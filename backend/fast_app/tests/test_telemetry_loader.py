import pytest
import pandas as pd
import os
import hashlib
from types import SimpleNamespace

from fast_app.telemetry_loader import TelemetryLoader


@pytest.fixture(autouse=True)
def clear_processed_cache_state():
    TelemetryLoader._fastf1_processed_cache.clear()
    yield
    TelemetryLoader._fastf1_processed_cache.clear()


def test_load_from_csv_missing_csv_raises_file_not_found(monkeypatch):
    csv_path = "data/session.csv"

    monkeypatch.setattr("fast_app.telemetry_loader.os.path.exists", lambda _p: False)

    with pytest.raises(FileNotFoundError, match="CSV file not found"):
        TelemetryLoader.load_from_csv(csv_path)


def test_load_from_csv_missing_meta_raises_file_not_found(monkeypatch):
    csv_path = "data/session.csv"
    path, filename = os.path.split(csv_path)
    name, ext = os.path.splitext(filename)
    meta_path = os.path.join(path, "meta", f"{name}Meta{ext}")

    def fake_exists(path: str) -> bool:
        if path == csv_path:
            return True
        if path == meta_path:
            return False
        return False

    monkeypatch.setattr("fast_app.telemetry_loader.os.path.exists", fake_exists)
    monkeypatch.setattr(
        "fast_app.telemetry_loader.pd.read_csv",
        lambda _path: None,
    )

    with pytest.raises(FileNotFoundError, match="sessionMeta.csv"):
        TelemetryLoader.load_from_csv(csv_path)


@pytest.mark.parametrize(
    "telemetry_df,expected_best_lap_number,expected_best_lap_time",
    [
        (
            pd.DataFrame(
                {
                    "Time (s)": [0.0, 10.0, 20.0],
                    "Last Lap Time (s)": [0.0, 82.0, 79.0],
                    "Session Lap Count": [1, 2, 3],
                    "Car Coord X (m)": [100.0, 101.0, 102.0],
                    "Car Coord Y (m)": [200.0, 201.0, 202.0],
                }
            ),
            2,
            79.0,
        ),
        (
            pd.DataFrame(
                {
                    "Time (s)": [0.0, 10.0, 20.0],
                    "Last Lap Time (s)": [0.0, 82.0, 79.0],
                    "Session Lap Count": [1, 2, 3],
                    "Lap Invalidated": [0, 1, 0],
                    "Car Coord X (m)": [100.0, 101.0, 102.0],
                    "Car Coord Y (m)": [200.0, 201.0, 202.0],
                }
            ),
            2,
            79.0,
        ),
    ],
)
def test_load_from_csv_success_handles_best_lap_and_column_rename(
    monkeypatch,
    telemetry_df,
    expected_best_lap_number,
    expected_best_lap_time,
):
    csv_path = "data/session.csv"
    path, filename = os.path.split(csv_path)
    name, ext = os.path.splitext(filename)
    meta_path = os.path.join(path, "meta", f"{name}Meta{ext}")
    meta_df = pd.DataFrame(
        [
            {
                "Venue": "Silverstone",
                "Vehicle": "F1 Car",
                "MaxSpeed": 320.0,
            }
        ]
    )

    def fake_exists(path: str) -> bool:
        return path in {csv_path, meta_path}

    def fake_read_csv(path: str):
        if path == csv_path:
            return telemetry_df.copy()
        if path == meta_path:
            return meta_df.copy()
        raise AssertionError(f"Unexpected read_csv path: {path}")

    monkeypatch.setattr("fast_app.telemetry_loader.os.path.exists", fake_exists)
    monkeypatch.setattr("fast_app.telemetry_loader.pd.read_csv", fake_read_csv)

    drivers_data, session_info = TelemetryLoader.load_from_csv(csv_path)

    assert "PLAYER" in drivers_data
    loaded_df = drivers_data["PLAYER"]
    assert "X" in loaded_df.columns
    assert "Y" in loaded_df.columns
    assert "Car Coord X (m)" not in loaded_df.columns
    assert "Car Coord Y (m)" not in loaded_df.columns
    assert "Time_s" in loaded_df.columns

    assert session_info["best_lap_number"] == expected_best_lap_number
    assert session_info["best_lap_time"] == expected_best_lap_time
    assert session_info["Venue"] == "Silverstone"
    assert session_info["Vehicle"] == "F1 Car"


def test_resolve_cache_path_uses_fastf1_cache_env(monkeypatch, tmp_path):
    custom_cache = str(tmp_path / "fastf1-cache")
    monkeypatch.setenv("FASTF1_CACHE", custom_cache)

    resolved = TelemetryLoader._resolve_cache_path("cache")

    assert resolved == custom_cache


def test_resolve_cache_path_converts_relative_path_to_absolute():
    resolved = TelemetryLoader._resolve_cache_path("relative/cache")

    assert os.path.isabs(resolved)
    assert resolved.endswith(os.path.join("relative", "cache"))


def test_processed_cache_file_path_uses_hash_when_location_slug_is_empty(tmp_path):
    location = "!!!"
    normalized = location.strip().lower()
    expected_slug = hashlib.sha1(normalized.encode("utf-8")).hexdigest()[:12]

    cache_file = TelemetryLoader._processed_cache_file_path(
        year=2025,
        location=location,
        session_type="r",
        cache_path=str(tmp_path),
    )

    assert cache_file.endswith(
        os.path.join("processed_payloads", f"v2_2025_R_{expected_slug}.pkl")
    )


def test_extract_fastf1_driver_metadata_prefers_results_rows():
    results = pd.DataFrame(
        [
            {
                "Abbreviation": "SAI",
                "TeamName": "Ferrari",
                "FullName": "Carlos Sainz",
                "DriverNumber": "55",
            },
            {
                "Abbreviation": "HAD",
                "TeamName": "RB",
                "FullName": "Isack Hadjar",
                "DriverNumber": "6",
            },
        ]
    )
    session = SimpleNamespace(results=results)

    metadata = TelemetryLoader._extract_fastf1_driver_metadata(
        session,
        ("SAI", "HAD"),
        year=2025,
        location="Shanghai",
    )

    assert metadata == {
        "SAI": {
            "team_name": "Ferrari",
            "driver_name": "Carlos Sainz",
            "driver_number": "55",
        },
        "HAD": {
            "team_name": "RB",
            "driver_name": "Isack Hadjar",
            "driver_number": "6",
        },
    }


def test_save_and_load_persisted_processed_cache_round_trip(tmp_path):
    payload = (
        {"HAM": pd.DataFrame({"Time_s": [0.0, 1.0], "Speed": [100.0, 110.0]})},
        {"drivers": ["HAM"], "session_name": "Race"},
    )

    TelemetryLoader._save_persisted_processed_cache(
        year=2025,
        location="Monza",
        session_type="R",
        cache_path=str(tmp_path),
        payload=payload,
    )

    assert TelemetryLoader.has_persisted_processed_cache(
        year=2025,
        location="Monza",
        session_type="R",
        cache_path=str(tmp_path),
    )

    loaded_payload = TelemetryLoader._load_persisted_processed_cache(
        year=2025,
        location="Monza",
        session_type="R",
        cache_path=str(tmp_path),
    )

    assert loaded_payload is not None
    assert loaded_payload[1]["drivers"] == payload[1]["drivers"]
    assert loaded_payload[1]["session_name"] == payload[1]["session_name"]
    assert loaded_payload[1]["driver_metadata"]["HAM"]["team_name"] == "Ferrari"
    assert loaded_payload[0]["HAM"].equals(payload[0]["HAM"])


def test_load_persisted_processed_cache_rejects_invalid_payload(tmp_path):
    cache_file = TelemetryLoader._processed_cache_file_path(
        year=2025,
        location="Monaco",
        session_type="R",
        cache_path=str(tmp_path),
    )
    os.makedirs(os.path.dirname(cache_file), exist_ok=True)
    with open(cache_file, "wb") as outfile:
        import pickle

        pickle.dump({"not": "a_valid_payload_tuple"}, outfile)

    loaded_payload = TelemetryLoader._load_persisted_processed_cache(
        year=2025,
        location="Monaco",
        session_type="R",
        cache_path=str(tmp_path),
    )

    assert loaded_payload is None


def test_load_from_fastf1_returns_in_memory_cache_without_session_call(monkeypatch):
    payload = ({"HAM": pd.DataFrame({"Speed": [320.0]})}, {"drivers": ["HAM"]})
    cache_key = (2025, "Monza", "R", ("__ALL__",))
    TelemetryLoader._fastf1_processed_cache[cache_key] = payload

    def fail_if_called(*_args, **_kwargs):
        raise AssertionError("fastf1.get_session should not be called when cache hits")

    monkeypatch.setattr("fast_app.telemetry_loader.fastf1.get_session", fail_if_called)

    loaded_payload = TelemetryLoader.load_from_fastf1(
        year=2025,
        location="Monza",
        session_type="R",
    )

    assert loaded_payload is payload


def test_load_from_fastf1_uses_persisted_payload_for_all_drivers(monkeypatch, tmp_path):
    payload = (
        {
            "HAM": pd.DataFrame({"Speed": [310.0]}),
            "VER": pd.DataFrame({"Speed": [312.0]}),
        },
        {"drivers": ["HAM", "VER"], "session_name": "Race"},
    )

    monkeypatch.setattr(
        TelemetryLoader,
        "_load_persisted_processed_cache",
        staticmethod(lambda year, location, session_type, cache_path: payload),
    )

    def fail_if_called(*_args, **_kwargs):
        raise AssertionError("fastf1.get_session should not be called on disk cache hit")

    monkeypatch.setattr("fast_app.telemetry_loader.fastf1.get_session", fail_if_called)

    loaded_payload = TelemetryLoader.load_from_fastf1(
        year=2025,
        location="Monza",
        session_type="R",
        cache_path=str(tmp_path),
    )

    assert loaded_payload == payload
    assert (2025, "Monza", "R", ("__ALL__",)) in TelemetryLoader._fastf1_processed_cache
    assert (2025, "Monza", "R", ("HAM", "VER")) in TelemetryLoader._fastf1_processed_cache


def test_warm_fastf1_processed_cache_delegates_to_loader(monkeypatch):
    called = {}

    def fake_load_from_fastf1(year, location, session_type, drivers=None, cache_path="cache"):
        called["args"] = (year, location, session_type, drivers, cache_path)
        return ({}, {})

    monkeypatch.setattr(
        TelemetryLoader,
        "load_from_fastf1",
        staticmethod(fake_load_from_fastf1),
    )

    TelemetryLoader.warm_fastf1_processed_cache(
        year=2025,
        location="Suzuka",
        session_type="R",
        drivers=["HAM"],
        cache_path="cache",
    )

    assert called["args"] == (2025, "Suzuka", "R", ["HAM"], "cache")

def test_ensure_driver_metadata_returns_payload_unchanged_when_session_info_not_dict():
    drivers_data = {"HAM": pd.DataFrame({"Speed": [300.0]})}
    payload = (drivers_data, "not a dict")
    
    result = TelemetryLoader._ensure_driver_metadata(
        payload,
        year=2025,
        location="Silverstone",
    )
    
    assert result == payload

def test_extract_fastf1_driver_metadata_falls_back_to_get_driver(monkeypatch):
    from types import SimpleNamespace

    results = pd.DataFrame(columns=["Abbreviation", "TeamName", "FullName", "DriverNumber"])
    session = SimpleNamespace(
        results=results,
        get_driver=lambda code: {
            "TeamName": "Mercedes",
            "FirstName": "Lewis",
            "LastName": "Hamilton",
            "DriverNumber": "44",
        }
    )

    metadata = TelemetryLoader._extract_fastf1_driver_metadata(
        session,
        active_drivers=("HAM",),
        year=2024,
        location="Silverstone",
    )

    assert metadata["HAM"]["team_name"] == "Mercedes"
    assert metadata["HAM"]["driver_name"] == "Lewis Hamilton"
    assert metadata["HAM"]["driver_number"] == "44"

def test_load_from_fastf1_raises_when_no_drivers_in_session(monkeypatch, tmp_path):
    import fastf1
    
    mock_laps = pd.DataFrame({"Driver": []})
    mock_session = SimpleNamespace(
        laps=mock_laps,
        results=pd.DataFrame(),
        weather_data=pd.DataFrame(),
        event={"EventName": "Test GP", "Location": "Silverstone"},
        name="Race",
    )
    mock_session.laps.pick_fastest = lambda: None

    monkeypatch.setattr("fast_app.telemetry_loader.fastf1.Cache.enable_cache", lambda _: None)
    monkeypatch.setattr("fast_app.telemetry_loader.fastf1.get_session", lambda *a, **kw: mock_session)
    mock_session.load = lambda: None

    with pytest.raises(ValueError, match="No drivers available"):
        TelemetryLoader.load_from_fastf1(
            year=2024,
            location="Silverstone",
            session_type="R",
            cache_path=str(tmp_path),
        )

def test_load_from_fastf1_raises_when_no_telemetry_available(monkeypatch, tmp_path):
    mock_laps = pd.DataFrame({"Driver": ["HAM"], "LapNumber": [1]})
    mock_laps.pick_fastest = lambda: None
    mock_laps.pick_drivers = lambda driver: pd.DataFrame()  # empty telemetry for all drivers

    mock_session = SimpleNamespace(
        laps=mock_laps,
        results=pd.DataFrame(),
        weather_data=pd.DataFrame(),
        event={"EventName": "Test GP", "Location": "Silverstone"},
        name="Race",
    )
    mock_session.load = lambda: None

    monkeypatch.setattr("fast_app.telemetry_loader.fastf1.Cache.enable_cache", lambda _: None)
    monkeypatch.setattr("fast_app.telemetry_loader.fastf1.get_session", lambda *a, **kw: mock_session)

    with pytest.raises(ValueError, match="No telemetry available"):
        TelemetryLoader.load_from_fastf1(
            year=2024,
            location="Silverstone",
            session_type="R",
            cache_path=str(tmp_path),
        )

def test_load_from_fastf1_success_with_mocked_session(monkeypatch, tmp_path):
    telemetry_df = pd.DataFrame({
        "Time": pd.to_timedelta([0, 1, 2], unit='s'),
        "X": [100.0, 101.0, 102.0],
        "Y": [200.0, 201.0, 202.0],
        "Speed": [300.0, 310.0, 320.0],
        "Distance": [0.0, 10.0, 20.0],
        "LapStartTime": pd.to_timedelta([0, 0, 0], unit='s'),
    })

    mock_lap = SimpleNamespace(
        empty=False,
        get=lambda key: pd.to_timedelta(0, unit='s') if key == 'LapStartTime' else 1,
        get_telemetry=lambda: SimpleNamespace(
            empty=False,
            add_distance=lambda: telemetry_df.copy(),
        ),
    )

    mock_laps = pd.DataFrame({"Driver": ["HAM"], "LapNumber": [1]})
    mock_laps.pick_fastest = lambda: SimpleNamespace(
        empty=False,
        get=lambda key: 1 if key == 'LapNumber' else pd.to_timedelta(90, unit='s'),
    )
    mock_laps.pick_drivers = lambda driver: SimpleNamespace(
        empty=False,
        iterlaps=lambda: [(0, mock_lap)],
    )

    mock_session = SimpleNamespace(
        laps=mock_laps,
        results=pd.DataFrame(),
        weather_data=pd.DataFrame({"AirTemp": [25.0], "TrackTemp": [40.0], "Rainfall": [0.0]}),
        event={"EventName": "British GP", "Location": "Silverstone"},
        name="Race",
        load=lambda: None,
    )

    monkeypatch.setattr("fast_app.telemetry_loader.fastf1.Cache.enable_cache", lambda _: None)
    monkeypatch.setattr("fast_app.telemetry_loader.fastf1.get_session", lambda *a, **kw: mock_session)

    drivers_data, session_info = TelemetryLoader.load_from_fastf1(
        year=2024,
        location="Silverstone",
        session_type="R",
        cache_path=str(tmp_path),
    )

    assert "HAM" in drivers_data
    assert session_info["event"] == "British GP"
    assert session_info["location"] == "Silverstone"

def test_load_from_fastf1_with_specific_drivers(monkeypatch, tmp_path):
    telemetry_df = pd.DataFrame({
        "Time": pd.to_timedelta([0, 1, 2], unit='s'),
        "X": [100.0, 101.0, 102.0],
        "Y": [200.0, 201.0, 202.0],
        "Speed": [300.0, 310.0, 320.0],
        "Distance": [0.0, 10.0, 20.0],
    })

    mock_lap = SimpleNamespace(
        empty=False,
        get=lambda key: pd.to_timedelta(0, unit='s') if key == 'LapStartTime' else 1,
        get_telemetry=lambda: SimpleNamespace(
            empty=False,
            add_distance=lambda: telemetry_df.copy(),
        ),
    )

    mock_laps = pd.DataFrame({"Driver": ["VER"], "LapNumber": [1]})
    mock_laps.pick_fastest = lambda: None
    mock_laps.pick_drivers = lambda driver: SimpleNamespace(
        empty=False,
        iterlaps=lambda: [(0, mock_lap)],
    )

    mock_session = SimpleNamespace(
        laps=mock_laps,
        results=pd.DataFrame(),
        weather_data=pd.DataFrame(),
        event={"EventName": "Dutch GP", "Location": "Zandvoort"},
        name="Race",
        load=lambda: None,
    )

    monkeypatch.setattr("fast_app.telemetry_loader.fastf1.Cache.enable_cache", lambda _: None)
    monkeypatch.setattr("fast_app.telemetry_loader.fastf1.get_session", lambda *a, **kw: mock_session)

    drivers_data, session_info = TelemetryLoader.load_from_fastf1(
        year=2024,
        location="Zandvoort",
        session_type="R",
        drivers=["VER"],
        cache_path=str(tmp_path),
    )

    assert "VER" in drivers_data
    assert session_info["location"] == "Zandvoort"
