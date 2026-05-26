import sys
import types
import pytest

if "models.commentary_models" not in sys.modules:
    stub = types.ModuleType("models.commentary_models")
    stub.TelemetryData = type("TelemetryData", (), {})
    sys.modules["models.commentary_models"] = stub

csv_service = pytest.importorskip(
    "fast_app.services.csv_telemetry_service",
    reason="csv_telemetry_service module not available on this branch",
)
list_available_csvs = csv_service.list_available_csvs
parse_csv_metadata = csv_service.parse_csv_metadata
parse_csv_filename = csv_service.parse_csv_filename


def test_list_available_csvs_excludes_meta_files(tmp_path):
    (tmp_path / "lap.csv").write_text("a,b\n1,2\n", encoding="utf-8")
    (tmp_path / "lapMeta.csv").write_text("k,v\nx,y\n", encoding="utf-8")
    (tmp_path / "notes.txt").write_text("ignore", encoding="utf-8")

    result = list_available_csvs(str(tmp_path))

    assert "lap.csv" in result
    assert "lapMeta.csv" not in result
    assert all(name.endswith(".csv") for name in result)


def test_parse_csv_filename_extracts_parts():
    data = parse_csv_filename("ks_brands_hatch_ac_legends_bmw_csl_08-10-2025_22-56-00.csv")

    assert data["venue"] == "ks_brands_hatch"
    assert data["vehicle"] == "ac_legends_bmw_csl"
    assert data["date"] == "08-10-2025"
    assert data["time"] == "22-56-00"


def test_parse_csv_filename_returns_unknown_for_short_names():
    data = parse_csv_filename("bad.csv")

    assert data == {
        "venue": "unknown",
        "vehicle": "unknown",
        "date": "unknown",
        "time": "unknown",
    }


def test_parse_csv_metadata_falls_back_to_filename_when_meta_missing(monkeypatch):
    monkeypatch.setattr("fast_app.services.csv_telemetry_service.os.path.exists", lambda _p: False)

    data = parse_csv_metadata(
        "ks_brands_hatch_ac_legends_bmw_csl_08-10-2025_22-56-00.csv",
        r"C:\data",
    )

    assert data["venue"] == "ks_brands_hatch"
    assert data["vehicle"] == "ac_legends_bmw_csl"
    assert data["date"] == "08-10-2025"
    assert data["time"] == "22-56-00"
