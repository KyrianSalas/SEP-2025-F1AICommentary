import fastf1
import datetime
import threading
import os
import json
import pandas as pd
from .telemetry_loader import TelemetryLoader

CACHED_RACES = {}
RACE_WARM_STATUS = {}
_status_lock = threading.Lock()
_warmup_lock = threading.Lock()
_BACKEND_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
_CACHE_DIR = os.path.abspath(os.environ.get('FASTF1_CACHE', os.path.join(_BACKEND_ROOT, 'cache')))
_READY_MARKERS_PATH = os.path.join(_CACHE_DIR, 'warm_ready_races.json')
_warmup_state = {
    "thread": None,
    "ready_race_markers": set(),
}


def _race_status_key(year: int, location: str, session_type: str = 'R') -> str:
    normalized_location = str(location).strip().lower()
    normalized_session_type = str(session_type).strip().upper()
    return f"{int(year)}|{normalized_location}|{normalized_session_type}"


def _load_ready_markers() -> set:
    if not os.path.exists(_READY_MARKERS_PATH):
        return set()

    try:
        with open(_READY_MARKERS_PATH, 'r', encoding='utf-8') as infile:
            payload = json.load(infile)
        if isinstance(payload, list):
            return {str(item) for item in payload}
    except (OSError, json.JSONDecodeError, TypeError, ValueError) as e:
        print(f"Failed to read warmup markers at {_READY_MARKERS_PATH}: {e}")
    return set()


def _persist_ready_markers() -> None:
    try:
        os.makedirs(os.path.dirname(_READY_MARKERS_PATH), exist_ok=True)
        with open(_READY_MARKERS_PATH, 'w', encoding='utf-8') as outfile:
            json.dump(sorted(_warmup_state["ready_race_markers"]), outfile)
    except (OSError, TypeError, ValueError) as e:
        print(f"Failed to persist warmup markers at {_READY_MARKERS_PATH}: {e}")


def _set_race_status(year: int, location: str, status: str, session_type: str = 'R', message: str = None) -> None:
    is_ready = status == "ready"
    status_message = message if message is not None else status
    cache_key = _race_status_key(year, location, session_type)

    with _status_lock:
        RACE_WARM_STATUS[cache_key] = {
            "status": status,
            "ready": is_ready,
            "message": status_message,
        }

        races = CACHED_RACES.get(str(int(year)), [])
        for race in races:
            if str(race.get("location", "")).strip().lower() == str(location).strip().lower():
                race["status"] = status
                race["ready"] = is_ready
                race["message"] = status_message


def get_cached_races_payload() -> dict:
    with _status_lock:
        return {
            year: [dict(race) for race in races]
            for year, races in CACHED_RACES.items()
        }


def is_race_ready(year: int, location: str, session_type: str = 'R') -> bool:
    cache_key = _race_status_key(year, location, session_type)
    with _status_lock:
        status_payload = RACE_WARM_STATUS.get(cache_key)
        if status_payload is not None:
            return bool(status_payload.get("ready", False))

        races = CACHED_RACES.get(str(int(year)), [])
        for race in races:
            if str(race.get("location", "")).strip().lower() == str(location).strip().lower():
                return bool(race.get("ready", False))

    return TelemetryLoader.has_persisted_processed_cache(
        year=int(year),
        location=location,
        session_type=session_type,
        cache_path=_CACHE_DIR,
    )

def preload_races(years_back=2, warm_telemetry=True, run_in_background=True):
    current_year = datetime.datetime.now().year
    years = list(range(current_year - years_back, current_year + 1))
    
    print("Pre-loading FastF1 schedules into memory...")
    try:
        fastf1.Cache.enable_cache(_CACHE_DIR)
    except Exception:
        pass

    _warmup_state["ready_race_markers"] = _load_ready_markers()
        
    with _status_lock:
        CACHED_RACES.clear()
        RACE_WARM_STATUS.clear()

    for y in years:
        try:
            schedule = fastf1.get_event_schedule(y)
            schedule = schedule[schedule['EventFormat'] != 'testing']
            schedule = schedule[schedule['RoundNumber'].fillna(0).astype(int) <= 3]
            
            races_for_year = []
            for _, row in schedule.iterrows():
                event_date = pd.to_datetime(row['EventDate']).tz_localize(None)
                if event_date < datetime.datetime.now():
                    race_location = row['Location']
                    race_key = _race_status_key(y, race_location, 'R')
                    has_persisted_payload = TelemetryLoader.has_persisted_processed_cache(
                        year=y,
                        location=race_location,
                        session_type='R',
                        cache_path=_CACHE_DIR,
                    )
                    is_ready = has_persisted_payload or race_key in _warmup_state["ready_race_markers"]
                    status = 'ready' if is_ready else 'race-loading'
                    races_for_year.append({
                        "name": row['EventName'],
                        "location": race_location,
                        "round": row.get('RoundNumber', 0),
                        "status": status,
                        "ready": is_ready,
                        "message": status,
                    })

            races_for_year.sort(key=lambda race: int(race.get("round", 0) or 0))
            
            if races_for_year:
                CACHED_RACES[str(y)] = races_for_year
                for race in races_for_year:
                    race_is_ready = bool(race.get('ready', False))
                    race_status = 'ready' if race_is_ready else 'race-loading'
                    _set_race_status(
                        year=y,
                        location=race['location'],
                        session_type='R',
                        status=race_status,
                        message=race_status,
                    )
        except Exception as e:
            print(f"Could not load races for year {y}: {e}")
    
    print("Pre-loaded years:", list(CACHED_RACES.keys()))

    if warm_telemetry:
        if run_in_background:
            with _warmup_lock:
                current_thread = _warmup_state["thread"]
                if current_thread is not None and current_thread.is_alive():
                    print("Background telemetry warmup already running; skipping duplicate start.")
                else:
                    print("Starting background telemetry warmup...")
                    _warmup_state["thread"] = threading.Thread(target=_background_cache_telemetry, daemon=True)
                    _warmup_state["thread"].start()
        else:
            print("Warming telemetry cache at startup (blocking)...")
            _background_cache_telemetry()

def _background_cache_telemetry():
    """Warm processed telemetry for cached races so session creation is instant."""
    for year, races in CACHED_RACES.items():
        total_races = len(races)
        for idx, race in enumerate(races, start=1):
            try:
                if is_race_ready(year=int(year), location=race['location'], session_type='R'):
                    print(f"[Cache Warmup] Skipping already-ready race {year} {race['name']}")
                    continue

                _set_race_status(
                    year=int(year),
                    location=race['location'],
                    session_type='R',
                    status='race-loading',
                    message='race-loading',
                )
                print(
                    f"[Cache Warmup] {year} race {idx}/{total_races}: "
                    f"{race['name']} ({race['location']})"
                )
                TelemetryLoader.warm_fastf1_processed_cache(
                    year=int(year),
                    location=race['location'],
                    session_type='R',
                    cache_path=_CACHE_DIR,
                )
                _set_race_status(
                    year=int(year),
                    location=race['location'],
                    session_type='R',
                    status='ready',
                    message='ready',
                )
                _warmup_state["ready_race_markers"].add(_race_status_key(int(year), race['location'], 'R'))
                _persist_ready_markers()
                print(f"[Cache Warmup] Completed {year} {race['name']}")
            except Exception as e:
                _set_race_status(
                    year=int(year),
                    location=race['location'],
                    session_type='R',
                    status='error',
                    message='race-loading',
                )
                print(f"[Cache Daemon] Skipped {year} {race['name']}: {e}")
                
    print("All configured telemetry has been cached!")
    with _warmup_lock:
        _warmup_state["thread"] = None
