import os
import re
import pickle
import hashlib
import pandas as pd
import fastf1
from typing import Dict, Tuple, List, Optional
from threading import Lock


class TelemetryLoader:
    _PROCESSED_CACHE_VERSION = 2
    _fastf1_processed_cache: Dict[Tuple[int, str, str, Tuple[str, ...]], Tuple[Dict[str, pd.DataFrame], Dict]] = {}
    _cache_lock = Lock()

    @staticmethod
    def _resolve_cache_path(cache_path: str) -> str:
        backend_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
        default_cache_dir = os.environ.get('FASTF1_CACHE', os.path.join(backend_root, 'cache'))
        resolved = default_cache_dir if cache_path == 'cache' else cache_path
        if not os.path.isabs(resolved):
            resolved = os.path.abspath(resolved)
        return resolved

    @staticmethod
    def _processed_cache_file_path(year: int, location: str, session_type: str, cache_path: str) -> str:
        normalized_location = str(location).strip().lower()
        location_slug = re.sub(r'[^a-z0-9]+', '_', normalized_location).strip('_')
        if not location_slug:
            location_slug = hashlib.sha1(normalized_location.encode('utf-8')).hexdigest()[:12]

        payload_dir = os.path.join(cache_path, 'processed_payloads')
        filename = (
            f"v{TelemetryLoader._PROCESSED_CACHE_VERSION}_"
            f"{int(year)}_{str(session_type).upper().strip()}_{location_slug}.pkl"
        )
        return os.path.join(payload_dir, filename)

    @staticmethod
    def _legacy_processed_cache_file_path(year: int, location: str, session_type: str, cache_path: str) -> str:
        normalized_location = str(location).strip().lower()
        location_slug = re.sub(r'[^a-z0-9]+', '_', normalized_location).strip('_')
        if not location_slug:
            location_slug = hashlib.sha1(normalized_location.encode('utf-8')).hexdigest()[:12]

        payload_dir = os.path.join(cache_path, 'processed_payloads')
        filename = f"{int(year)}_{str(session_type).upper().strip()}_{location_slug}.pkl"
        return os.path.join(payload_dir, filename)

    @staticmethod
    def _fallback_fastf1_driver_metadata(
        year: int,
        location: str,
        active_drivers: Tuple[str, ...],
    ) -> Dict[str, Dict[str, str]]:
        normalized_location = str(location).strip().lower()
        is_early_2025 = int(year) == 2025 and normalized_location in {
            "melbourne",
            "shanghai",
        }

        driver_teams_2024 = {
            "ALB": "Williams",
            "ALO": "Aston Martin",
            "BOT": "Kick Sauber",
            "GAS": "Alpine",
            "HAM": "Mercedes",
            "HUL": "Haas",
            "LEC": "Ferrari",
            "MAG": "Haas",
            "NOR": "McLaren",
            "OCO": "Alpine",
            "PER": "Red Bull",
            "PIA": "McLaren",
            "RIC": "RB",
            "RUS": "Mercedes",
            "SAI": "Ferrari",
            "SAR": "Williams",
            "STR": "Aston Martin",
            "TSU": "RB",
            "VER": "Red Bull",
            "ZHO": "Kick Sauber",
        }
        driver_teams_2025_onward = {
            "ALB": "Williams",
            "ALO": "Aston Martin",
            "ANT": "Mercedes",
            "BEA": "Haas",
            "BOR": "Kick Sauber",
            "DOO": "Alpine",
            "GAS": "Alpine",
            "HAD": "RB",
            "HAM": "Ferrari",
            "HUL": "Kick Sauber",
            "LAW": "Red Bull" if is_early_2025 else "RB",
            "LEC": "Ferrari",
            "NOR": "McLaren",
            "OCO": "Haas",
            "PIA": "McLaren",
            "RUS": "Mercedes",
            "SAI": "Williams",
            "STR": "Aston Martin",
            "TSU": "RB" if is_early_2025 else "Red Bull",
            "VER": "Red Bull",
        }
        driver_teams = driver_teams_2024 if int(year) <= 2024 else driver_teams_2025_onward

        return {
            driver_code: {"team_name": team_name}
            for driver_code, team_name in driver_teams.items()
            if driver_code in active_drivers
        }

    @staticmethod
    def _ensure_driver_metadata(payload, year: int, location: str):
        if not isinstance(payload, tuple) or len(payload) != 2:
            return payload

        drivers_data, session_info = payload
        if not isinstance(session_info, dict):
            return payload

        drivers = tuple(
            str(driver).upper().strip()
            for driver in session_info.get("drivers", drivers_data.keys())
            if str(driver).strip()
        )
        fallback_metadata = TelemetryLoader._fallback_fastf1_driver_metadata(
            year=int(year),
            location=location,
            active_drivers=drivers,
        )

        metadata = dict(session_info.get("driver_metadata") or {})
        for driver_code, fallback in fallback_metadata.items():
            current = metadata.get(driver_code)
            if not isinstance(current, dict) or not current.get("team_name"):
                metadata[driver_code] = fallback

        if metadata:
            session_info = dict(session_info)
            session_info["driver_metadata"] = metadata

        return drivers_data, session_info

    @staticmethod
    def _extract_fastf1_driver_metadata(session, active_drivers: Tuple[str, ...], year: int, location: str) -> Dict[str, Dict[str, str]]:
        metadata: Dict[str, Dict[str, str]] = {}

        results = getattr(session, "results", None)
        if results is not None and not getattr(results, "empty", True):
            for _, row in results.iterrows():
                driver_code = str(row.get("Abbreviation", "")).upper().strip()
                if not driver_code or driver_code not in active_drivers:
                    continue

                metadata[driver_code] = {
                    "team_name": str(row.get("TeamName", "")).strip(),
                    "driver_name": str(row.get("FullName", "")).strip(),
                    "driver_number": str(row.get("DriverNumber", "")).strip(),
                }

        for driver_code in active_drivers:
            if driver_code in metadata and metadata[driver_code].get("team_name"):
                continue

            try:
                driver_info = session.get_driver(driver_code)
            except Exception:
                continue

            metadata[driver_code] = {
                "team_name": str(driver_info.get("TeamName", "")).strip(),
                "driver_name": " ".join(
                    part
                    for part in [
                        str(driver_info.get("FirstName", "")).strip(),
                        str(driver_info.get("LastName", "")).strip(),
                    ]
                    if part
                ).strip(),
                "driver_number": str(driver_info.get("DriverNumber", "")).strip(),
            }

        fallback_metadata = TelemetryLoader._fallback_fastf1_driver_metadata(
            year=int(year),
            location=location,
            active_drivers=active_drivers,
        )
        for driver_code, fallback in fallback_metadata.items():
            current = metadata.get(driver_code)
            if not isinstance(current, dict) or not current.get("team_name"):
                metadata[driver_code] = fallback

        return metadata

    @staticmethod
    def has_persisted_processed_cache(year: int, location: str, session_type: str, cache_path: str = 'cache') -> bool:
        resolved_cache_path = TelemetryLoader._resolve_cache_path(cache_path)
        payload_path = TelemetryLoader._processed_cache_file_path(year, location, session_type, resolved_cache_path)
        legacy_payload_path = TelemetryLoader._legacy_processed_cache_file_path(year, location, session_type, resolved_cache_path)
        return os.path.exists(payload_path) or os.path.exists(legacy_payload_path)

    @staticmethod
    def _load_persisted_processed_cache(year: int, location: str, session_type: str, cache_path: str):
        payload_paths = [
            TelemetryLoader._processed_cache_file_path(year, location, session_type, cache_path),
            TelemetryLoader._legacy_processed_cache_file_path(year, location, session_type, cache_path),
        ]

        for payload_path in payload_paths:
            if not os.path.exists(payload_path):
                continue

            try:
                with open(payload_path, 'rb') as infile:
                    payload = pickle.load(infile)
                if isinstance(payload, tuple) and len(payload) == 2:
                    return TelemetryLoader._ensure_driver_metadata(
                        payload,
                        year=int(year),
                        location=location,
                    )
            except (OSError, pickle.PickleError, ValueError, TypeError):
                continue
        return None

    @staticmethod
    def _save_persisted_processed_cache(
        year: int,
        location: str,
        session_type: str,
        cache_path: str,
        payload,
    ) -> None:
        payload_path = TelemetryLoader._processed_cache_file_path(year, location, session_type, cache_path)
        os.makedirs(os.path.dirname(payload_path), exist_ok=True)
        with open(payload_path, 'wb') as outfile:
            pickle.dump(payload, outfile)

    @staticmethod
    def load_from_csv(csv_path: str) -> Tuple[Dict[str, pd.DataFrame], Dict]:
        """
        Load telemetry from CSV file.
        Args:
            csv_path: Path to the CSV file
        Returns:
            Tuple of (drivers_data, session_info)
        """
        if not os.path.exists(csv_path):
            raise FileNotFoundError(f"CSV file not found: {csv_path}")
        
        df = pd.read_csv(csv_path)
        
        # Use csv path to find the path to the linked meta file in the form: path/meta/nameMeta.csv
        path, filename = os.path.split(csv_path)
        name, ext = os.path.splitext(filename)

        meta_csv_path = os.path.join(path, 'meta', f'{name}Meta{ext}')

        if not os.path.exists(meta_csv_path):
            raise FileNotFoundError(f'CSV file not found: {meta_csv_path}')

        meta_df = pd.read_csv(meta_csv_path)
        
        track = meta_df.Venue[0]
        car = meta_df.Vehicle[0]

        best_lap_number = None
        best_lap_time = None
        if 'Last Lap Time (s)' in df.columns and 'Session Lap Count' in df.columns:
            completed_laps = df[df['Last Lap Time (s)'] > 0]
            if 'Lap Invalidated' in df.columns:
                completed_laps = completed_laps[completed_laps['Lap Invalidated'] == 0]
            if not completed_laps.empty:
                idx = completed_laps['Last Lap Time (s)'].idxmin()
                best_lap_time = float(completed_laps.loc[idx, 'Last Lap Time (s)'])
                best_lap_number = int(completed_laps.loc[idx, 'Session Lap Count'] - 1)

        session_info = {
            "event": f"{track} - AC Session",
            "location": track,
            "car": car,
            "drivers": ["PLAYER"],
            "source": "csv",
            "session_name": "Practice",
            "filename": filename,
            "best_lap_number": best_lap_number,
            "best_lap_time": best_lap_time
        }

        # Append metadata onto session info
        session_info.update(meta_df.iloc[0].to_dict())


        # making it so it uses the same x,y as fastf1
        column_mapping = {
            'Car Coord X (m)': 'X',
            'Car Coord Y (m)': 'Y',
        }
        
        # (only rename columns that exist)
        rename_dict = {k: v for k, v in column_mapping.items() if k in df.columns}
        df = df.rename(columns=rename_dict)
        
        if 'Time (s)' in df.columns:
            df['Time_s'] = df['Time (s)']

        drivers_data = {
            "PLAYER": df
        }

        return drivers_data, session_info

    @staticmethod
    def load_from_fastf1(year: int, location: str, session_type: str, 
                        drivers: Optional[List[str]] = None, cache_path: str = 'cache') -> Tuple[Dict[str, pd.DataFrame], Dict]:
        """
        Load telemetry from Fastf1 API.
        Args:
            year: Race year
            location: Race location
            session_type: R (race), Q (qualifying), P (practice)
            drivers: Optional list of driver codes; if None, load all available drivers
            cache_path: Path to cache directory
            
        Returns:
            Tuple of (drivers_data, session_info)
        """
        normalized_location = str(location).strip()
        normalized_session_type = str(session_type).upper().strip()
        requested_drivers = None
        if drivers is not None:
            requested_drivers = tuple(sorted(str(driver).upper().strip() for driver in drivers))
        cache_key_drivers = requested_drivers if requested_drivers is not None else ("__ALL__",)
        cache_key = (int(year), normalized_location, normalized_session_type, cache_key_drivers)

        with TelemetryLoader._cache_lock:
            cached_payload = TelemetryLoader._fastf1_processed_cache.get(cache_key)
        if cached_payload is not None:
            print(f"[ProcessedCache] In-memory hit for {cache_key}")
            return cached_payload

        resolved_cache_path = TelemetryLoader._resolve_cache_path(cache_path)

        if requested_drivers is None:
            persisted_payload = TelemetryLoader._load_persisted_processed_cache(
                year=int(year),
                location=normalized_location,
                session_type=normalized_session_type,
                cache_path=resolved_cache_path,
            )
            if persisted_payload is not None:
                print(f"[ProcessedCache] Disk hit for {cache_key}")
                with TelemetryLoader._cache_lock:
                    TelemetryLoader._fastf1_processed_cache[cache_key] = persisted_payload
                    persisted_session_info = persisted_payload[1] if len(persisted_payload) > 1 else {}
                    discovered_drivers = tuple(persisted_session_info.get('drivers', []))
                    if discovered_drivers:
                        discovered_key = (
                            int(year),
                            normalized_location,
                            normalized_session_type,
                            discovered_drivers,
                        )
                        TelemetryLoader._fastf1_processed_cache[discovered_key] = persisted_payload
                return persisted_payload

        if not os.path.exists(resolved_cache_path):
            print(f"Cannot find cache at: {resolved_cache_path}, making one now.")
            os.makedirs(resolved_cache_path)
            
        
        fastf1.Cache.enable_cache(resolved_cache_path)
        session = fastf1.get_session(int(year), normalized_location, normalized_session_type)
        session.load()

        if requested_drivers is not None:
            active_drivers = requested_drivers
        else:
            if 'Driver' not in session.laps.columns:
                raise ValueError("FastF1 session laps do not include a Driver column")
            discovered = {
                str(driver).upper().strip()
                for driver in session.laps['Driver'].dropna().tolist()
                if str(driver).strip()
            }
            active_drivers = tuple(sorted(discovered))

        if not active_drivers:
            raise ValueError("No drivers available in FastF1 session data")

        driver_metadata = TelemetryLoader._extract_fastf1_driver_metadata(
            session,
            active_drivers,
            year=int(year),
            location=normalized_location,
        )

        best_lap_number = None
        best_lap_time = None
        try:
            fastest_lap = session.laps.pick_fastest()
            if fastest_lap is not None and not fastest_lap.empty:
                lap_number = fastest_lap.get('LapNumber')
                if pd.notna(lap_number):
                    best_lap_number = int(lap_number)

                lap_time = fastest_lap.get('LapTime')
                if pd.notna(lap_time):
                    best_lap_time = float(lap_time.total_seconds())
        except (TypeError, ValueError, KeyError, AttributeError):
            best_lap_number = None
            best_lap_time = None
        
        multi_data = {}
        for driver in active_drivers:
            driver_laps = session.laps.pick_drivers(driver)
            if driver_laps.empty:
                continue

            lap_telemetry_segments = []
            for _, lap in driver_laps.iterlaps():
                if lap is None or lap.empty:
                    continue

                telemetry = lap.get_telemetry().add_distance()
                if telemetry.empty:
                    continue

                # Build continuous race time in seconds for playback.
                lap_start_time = lap.get('LapStartTime')
                if pd.notna(lap_start_time):
                    telemetry['Time_s'] = (telemetry['Time'] + lap_start_time).dt.total_seconds()
                else:
                    telemetry['Time_s'] = telemetry['Time'].dt.total_seconds()

                lap_number = lap.get('LapNumber')
                if pd.notna(lap_number):
                    telemetry['Session Lap Count'] = int(lap_number)

                lap_telemetry_segments.append(telemetry)

            if not lap_telemetry_segments:
                continue

            full_race_telemetry = pd.concat(lap_telemetry_segments, ignore_index=True)

            # Forward-fill positional and speed NaNs that appear at lap boundaries
            # (FastF1 channel merging can leave NaN at the first sample of each lap).
            # Without this, X/Y=NaN → 0.0 in JSON → car snaps to origin on the map,
            # and Speed=NaN → 0 in the commentary snapshot → AI describes the car as stationary.
            for _col in ['X', 'Y', 'Speed']:
                if _col in full_race_telemetry.columns:
                    full_race_telemetry[_col] = full_race_telemetry[_col].ffill()

            multi_data[driver] = full_race_telemetry

        if not multi_data:
            raise ValueError("No telemetry available for requested FastF1 drivers")

        reference_driver = next(iter(multi_data.keys()))
        reference_df = multi_data[reference_driver]

        lap_indexes = [0]
        total_lap_count = 1
        if 'Session Lap Count' in reference_df.columns:
            lap_series = reference_df['Session Lap Count'].dropna().astype(int)
            if not lap_series.empty:
                lap_indexes = []
                last_lap = None
                for idx, lap_no in lap_series.items():
                    if last_lap != int(lap_no):
                        lap_indexes.append(int(idx))
                        last_lap = int(lap_no)
                if not lap_indexes:
                    lap_indexes = [0]

                total_lap_count = int(lap_series.max())

        def _max_from_columns(df: pd.DataFrame, candidates: List[str], default: float = 0.0) -> float:
            for col in candidates:
                if col in df.columns:
                    series = pd.to_numeric(df[col], errors='coerce').dropna()
                    if not series.empty:
                        return float(series.max())
            return default

        max_speed = _max_from_columns(reference_df, ['Ground Speed (km/h)', 'Speed', 'SpeedI1'], 0.0)
        max_rpm = int(_max_from_columns(reference_df, ['Engine RPM (rpm)', 'RPM'], 0.0))
        max_fuel = _max_from_columns(reference_df, ['Fuel Level (l)', 'Fuel'], 0.0)
        race_index_length = max(len(df) for df in multi_data.values())
        
        weather = session.weather_data.iloc[0].to_dict() if not session.weather_data.empty else {}
        
        session_info = {
            "event": session.event['EventName'],
            "location": session.event['Location'],
            "drivers": list(multi_data.keys()),
            "driver_metadata": driver_metadata,
            "source": "fastf1",
            "best_lap_number": best_lap_number,
            "best_lap_time": best_lap_time,
            "LapIndexes": lap_indexes,
            "TotalLapCount": total_lap_count,
            "RaceIndexLength": race_index_length,
            "MaxSpeed": max_speed,
            "Max RPM": max_rpm,
            "Max Fuel": max_fuel,
            "weather": {
                "air_temp": weather.get('AirTemp'),
                "track_temp": weather.get('TrackTemp'),
                "rainfall": weather.get('Rainfall')
            },
            "session_name": session.name
        }

        payload = (multi_data, session_info)
        with TelemetryLoader._cache_lock:
            TelemetryLoader._fastf1_processed_cache[cache_key] = payload
            if requested_drivers is None:
                discovered_key = (
                    int(year),
                    normalized_location,
                    normalized_session_type,
                    tuple(session_info['drivers']),
                )
                TelemetryLoader._fastf1_processed_cache[discovered_key] = payload

        if requested_drivers is None:
            try:
                TelemetryLoader._save_persisted_processed_cache(
                    year=int(year),
                    location=normalized_location,
                    session_type=normalized_session_type,
                    cache_path=resolved_cache_path,
                    payload=payload,
                )
            except OSError:
                pass
        return payload

    @staticmethod
    def warm_fastf1_processed_cache(year: int, location: str, session_type: str, drivers: Optional[List[str]] = None, cache_path: str = 'cache') -> None:
        """Pre-build and store processed FastF1 telemetry for faster session creation."""
        TelemetryLoader.load_from_fastf1(year=year, location=location, session_type=session_type, drivers=drivers, cache_path=cache_path)
