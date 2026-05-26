import json

import pandas as pd
import pytest

from fast_app import cache_service


@pytest.fixture(autouse=True)
def reset_cache_service_state():
    cache_service.CACHED_RACES.clear()
    cache_service.RACE_WARM_STATUS.clear()
    cache_service._warmup_state["ready_race_markers"] = set()
    cache_service._warmup_state["thread"] = None
    yield
    cache_service.CACHED_RACES.clear()
    cache_service.RACE_WARM_STATUS.clear()
    cache_service._warmup_state["ready_race_markers"] = set()
    cache_service._warmup_state["thread"] = None


def test_race_status_key_normalizes_year_location_and_session_type():
    key = cache_service._race_status_key(2025, "  Monza  ", "r")

    assert key == "2025|monza|R"


def test_load_ready_markers_returns_empty_set_when_file_missing(tmp_path, monkeypatch):
    ready_markers_path = tmp_path / "warm_ready_races.json"
    monkeypatch.setattr(cache_service, "_READY_MARKERS_PATH", str(ready_markers_path))

    assert cache_service._load_ready_markers() == set()


def test_load_ready_markers_reads_list_payload(tmp_path, monkeypatch):
    ready_markers_path = tmp_path / "warm_ready_races.json"
    ready_markers_path.write_text(
        json.dumps(["2025|bahrain|R", "2025|jeddah|R"]),
        encoding="utf-8",
    )
    monkeypatch.setattr(cache_service, "_READY_MARKERS_PATH", str(ready_markers_path))

    assert cache_service._load_ready_markers() == {"2025|bahrain|R", "2025|jeddah|R"}


def test_load_ready_markers_returns_empty_for_invalid_json(tmp_path, monkeypatch):
    ready_markers_path = tmp_path / "warm_ready_races.json"
    ready_markers_path.write_text("{not-valid-json", encoding="utf-8")
    monkeypatch.setattr(cache_service, "_READY_MARKERS_PATH", str(ready_markers_path))

    assert cache_service._load_ready_markers() == set()


def test_persist_ready_markers_writes_sorted_payload(tmp_path, monkeypatch):
    ready_markers_path = tmp_path / "nested" / "warm_ready_races.json"
    monkeypatch.setattr(cache_service, "_READY_MARKERS_PATH", str(ready_markers_path))
    cache_service._warmup_state["ready_race_markers"] = {"2025|jeddah|R", "2025|bahrain|R"}

    cache_service._persist_ready_markers()

    payload = json.loads(ready_markers_path.read_text(encoding="utf-8"))
    assert payload == ["2025|bahrain|R", "2025|jeddah|R"]


def test_set_race_status_updates_global_status_and_cached_race():
    cache_service.CACHED_RACES["2025"] = [
        {
            "name": "Italian Grand Prix",
            "location": "Monza",
            "status": "race-loading",
            "ready": False,
            "message": "race-loading",
        }
    ]

    cache_service._set_race_status(2025, " monza ", status="ready", session_type="r")

    cache_key = "2025|monza|R"
    assert cache_service.RACE_WARM_STATUS[cache_key]["status"] == "ready"
    assert cache_service.RACE_WARM_STATUS[cache_key]["ready"] is True
    assert cache_service.CACHED_RACES["2025"][0]["status"] == "ready"
    assert cache_service.CACHED_RACES["2025"][0]["ready"] is True


def test_get_cached_races_payload_returns_copy_not_live_reference():
    cache_service.CACHED_RACES["2025"] = [
        {"name": "Bahrain GP", "location": "Bahrain", "ready": True}
    ]

    payload = cache_service.get_cached_races_payload()
    payload["2025"][0]["name"] = "Changed"

    assert cache_service.CACHED_RACES["2025"][0]["name"] == "Bahrain GP"


def test_is_race_ready_prefers_explicit_status_payload(monkeypatch):
    cache_service.RACE_WARM_STATUS["2025|monza|R"] = {
        "status": "race-loading",
        "ready": False,
        "message": "race-loading",
    }
    cache_service.CACHED_RACES["2025"] = [{"location": "Monza", "ready": True}]

    def fail_if_called(*_args, **_kwargs):
        raise AssertionError("Disk fallback should not be used when status is known")

    monkeypatch.setattr(
        "fast_app.cache_service.TelemetryLoader.has_persisted_processed_cache",
        fail_if_called,
    )

    assert cache_service.is_race_ready(2025, "Monza", "R") is False


def test_is_race_ready_uses_cached_races_when_status_missing(monkeypatch):
    cache_service.CACHED_RACES["2025"] = [{"location": "MONZA", "ready": True}]

    def fail_if_called(*_args, **_kwargs):
        raise AssertionError("Disk fallback should not be used when race exists in cache")

    monkeypatch.setattr(
        "fast_app.cache_service.TelemetryLoader.has_persisted_processed_cache",
        fail_if_called,
    )

    assert cache_service.is_race_ready(2025, "monza", "R") is True


def test_is_race_ready_falls_back_to_persisted_cache(monkeypatch):
    monkeypatch.setattr(
        "fast_app.cache_service.TelemetryLoader.has_persisted_processed_cache",
        lambda year, location, session_type, cache_path: (
            year,
            location,
            session_type,
            cache_path,
        )
        == (2025, "Monaco", "R", cache_service._CACHE_DIR),
    )

    assert cache_service.is_race_ready(2025, "Monaco", "R") is True


def test_preload_races_filters_schedule_and_sets_ready_statuses(monkeypatch):
    schedule = pd.DataFrame(
        [
            {
                "EventFormat": "conventional",
                "RoundNumber": 1,
                "EventDate": "2000-03-01",
                "Location": "Bahrain",
                "EventName": "Bahrain GP",
            },
            {
                "EventFormat": "conventional",
                "RoundNumber": 3,
                "EventDate": "2000-03-15",
                "Location": "Jeddah",
                "EventName": "Saudi GP",
            },
            {
                "EventFormat": "testing",
                "RoundNumber": 2,
                "EventDate": "2000-01-10",
                "Location": "Sakhir",
                "EventName": "Testing",
            },
            {
                "EventFormat": "conventional",
                "RoundNumber": 4,
                "EventDate": "2000-04-01",
                "Location": "Suzuka",
                "EventName": "Round 4",
            },
            {
                "EventFormat": "conventional",
                "RoundNumber": 2,
                "EventDate": "2100-01-01",
                "Location": "Future",
                "EventName": "Future GP",
            },
        ]
    )

    jeddah_key = cache_service._race_status_key(2025, "Jeddah", "R")

    monkeypatch.setattr("fast_app.cache_service.fastf1.Cache.enable_cache", lambda _path: None)
    monkeypatch.setattr("fast_app.cache_service.fastf1.get_event_schedule", lambda _year: schedule)
    monkeypatch.setattr(cache_service, "_load_ready_markers", lambda: {jeddah_key})
    monkeypatch.setattr(
        "fast_app.cache_service.TelemetryLoader.has_persisted_processed_cache",
        lambda year, location, session_type, cache_path: location == "Bahrain",
    )

    cache_service.preload_races(warm_telemetry=False)

    races_2025 = cache_service.CACHED_RACES["2025"]
    assert [race["location"] for race in races_2025] == ["Bahrain", "Jeddah"]
    assert races_2025[0]["ready"] is True
    assert races_2025[1]["ready"] is True
    assert cache_service.RACE_WARM_STATUS["2025|bahrain|R"]["status"] == "ready"
    assert cache_service.RACE_WARM_STATUS["2025|jeddah|R"]["status"] == "ready"


def test_preload_races_blocking_warmup_calls_background_worker(monkeypatch):
    called = {"count": 0}
    empty_schedule = pd.DataFrame(
        columns=["EventFormat", "RoundNumber", "EventDate", "Location", "EventName"]
    )

    monkeypatch.setattr("fast_app.cache_service.fastf1.Cache.enable_cache", lambda _path: None)
    monkeypatch.setattr(
        "fast_app.cache_service.fastf1.get_event_schedule", lambda _year: empty_schedule
    )
    monkeypatch.setattr(cache_service, "_load_ready_markers", lambda: set())
    monkeypatch.setattr(
        cache_service,
        "_background_cache_telemetry",
        lambda: called.__setitem__("count", called["count"] + 1),
    )

    cache_service.preload_races(warm_telemetry=True, run_in_background=False)

    assert called["count"] == 1


def test_background_cache_telemetry_marks_race_ready_and_persists(monkeypatch):
    cache_service.CACHED_RACES["2025"] = [
        {"name": "Italian GP", "location": "Monza", "status": "race-loading", "ready": False}
    ]
    cache_service._warmup_state["thread"] = object()

    warmed = []
    persisted = []

    monkeypatch.setattr(cache_service, "is_race_ready", lambda year, location, session_type="R": False)
    monkeypatch.setattr(
        "fast_app.cache_service.TelemetryLoader.warm_fastf1_processed_cache",
        lambda year, location, session_type, cache_path: warmed.append(
            (year, location, session_type, cache_path)
        ),
    )
    monkeypatch.setattr(cache_service, "_persist_ready_markers", lambda: persisted.append(True))

    cache_service._background_cache_telemetry()

    race_key = cache_service._race_status_key(2025, "Monza", "R")
    assert warmed == [(2025, "Monza", "R", cache_service._CACHE_DIR)]
    assert cache_service.RACE_WARM_STATUS[race_key]["status"] == "ready"
    assert race_key in cache_service._warmup_state["ready_race_markers"]
    assert len(persisted) == 1
    assert cache_service._warmup_state["thread"] is None


def test_background_cache_telemetry_sets_error_when_warmup_raises(monkeypatch):
    cache_service.CACHED_RACES["2025"] = [
        {"name": "Monaco GP", "location": "Monaco", "status": "race-loading", "ready": False}
    ]

    def raise_on_warmup(*_args, **_kwargs):
        raise RuntimeError("warmup failed")

    monkeypatch.setattr(cache_service, "is_race_ready", lambda year, location, session_type="R": False)
    monkeypatch.setattr(
        "fast_app.cache_service.TelemetryLoader.warm_fastf1_processed_cache",
        raise_on_warmup,
    )

    cache_service._background_cache_telemetry()

    race_key = cache_service._race_status_key(2025, "Monaco", "R")
    assert cache_service.RACE_WARM_STATUS[race_key]["status"] == "error"
    assert cache_service.RACE_WARM_STATUS[race_key]["message"] == "race-loading"
