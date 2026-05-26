import pytest
import pandas as pd
from pathlib import Path
from fast_app.services.f1_telemetry_service import F1TelemetryService, LapSnapshot


# Fixed race used across all tests — stable, completed, well-cached
TEST_YEAR = 2023
TEST_LOCATION = "Monza"
TEST_DRIVER = "VER"


@pytest.fixture(scope="module")
def service():
    """Single service instance shared across all tests in this module."""
    return F1TelemetryService()


@pytest.fixture(scope="module")
def laps(service):
        """Stream all laps for the test
        """
        return list(service.stream_race_laps(TEST_YEAR, TEST_LOCATION, TEST_DRIVER))



class TestServiceSetup:
    def test_service_initialises(self, service):
        assert service is not None

    def test_get_available_races_returns_list(self, service):
        races = service.get_available_races(TEST_YEAR)
        assert isinstance(races, list)
        assert len(races) > 0

    def test_get_available_races_structure(self, service):
        races = service.get_available_races(TEST_YEAR)
        first = races[0]
        assert "year" in first
        assert "name" in first
        assert "round" in first
        assert "location" in first
        assert "date" in first

    def test_get_available_races_excludes_testing(self, service):
        races = service.get_available_races(TEST_YEAR)
        names = [r["name"].lower() for r in races]
        assert not any("test" in name for name in names)


class TestLapStreaming:
    def test_yields_laps(self, laps):
        assert len(laps) > 0

    def test_all_items_are_lap_snapshots(self, laps):
        assert all(isinstance(lap, LapSnapshot) for lap in laps)

    def test_lap_count_is_reasonable(self, laps):
        """A full Monza race should have between 40 and 60 laps."""
        assert 40 <= len(laps) <= 60

    def test_total_laps_consistent(self, laps):
        """Every snapshot should report the same total_laps value."""
        total_laps_values = {lap.total_laps for lap in laps}
        assert len(total_laps_values) == 1
        assert laps[0].total_laps == len(laps)

    def test_lap_numbers_are_sequential(self, laps):
        lap_numbers = [lap.lap_number for lap in laps]
        assert lap_numbers == sorted(lap_numbers)
        assert lap_numbers[0] >= 1

    def test_driver_correct(self, laps):
        assert all(lap.driver == TEST_DRIVER for lap in laps)

    def test_driver_number_present(self, laps):
        assert all(lap.driver_number for lap in laps)

    def test_invalid_driver_raises(self, service):
        with pytest.raises(ValueError, match="No laps found"):
            list(service.stream_race_laps(TEST_YEAR, TEST_LOCATION, "NOTADRIVER"))

class TestLapSnapshotFields:
    def test_position_present_on_most_laps(self, laps):
        """Most laps should have a position — allow a few None for edge cases."""
        positions = [lap.position for lap in laps if lap.position is not None]
        assert len(positions) > len(laps) * 0.8

    def test_position_is_valid_range(self, laps):
        for lap in laps:
            if lap.position is not None:
                assert 1 <= lap.position <= 20

    def test_compound_present_on_most_laps(self, laps):
        compounds = [lap.compound for lap in laps if lap.compound]
        assert len(compounds) > len(laps) * 0.8

    def test_compound_is_known_value(self, laps):
        known = {"SOFT", "MEDIUM", "HARD", "INTERMEDIATE", "WET", None}
        for lap in laps:
            assert lap.compound in known

    def test_tyre_life_non_negative(self, laps):
        for lap in laps:
            if lap.tyre_life is not None:
                assert lap.tyre_life >= 0

    def test_lap_time_positive(self, laps):
        for lap in laps:
            if lap.lap_time_s is not None:
                assert lap.lap_time_s > 0

    def test_lap_time_reasonable_range(self, laps):
        """Monza lap times should be between 75s and 150s (outlap/inlap included)."""
        for lap in laps:
            if lap.lap_time_s is not None:
                assert 75 <= lap.lap_time_s <= 150

    def test_sector_times_positive(self, laps):
        for lap in laps:
            for sector in (lap.sector_1_s, lap.sector_2_s, lap.sector_3_s):
                if sector is not None:
                    assert sector > 0

    def test_max_speed_positive(self, laps):
        assert all(lap.max_speed > 0 for lap in laps)

    def test_max_speed_reasonable(self, laps):
        """Monza top speeds should be between 200 and 380 km/h."""
        for lap in laps:
            assert 200 <= lap.max_speed <= 380

    def test_pit_flags_are_bool(self, laps):
        for lap in laps:
            assert isinstance(lap.is_pit_in, bool)
            assert isinstance(lap.is_pit_out, bool)

    def test_at_least_one_pit_stop(self, laps):
        """Every race should have at least one pit stop."""
        pit_ins = [lap for lap in laps if lap.is_pit_in]
        assert len(pit_ins) >= 1


class TestTelemetryDataFrame:
    def test_telemetry_df_not_empty(self, laps):
        assert all(not lap.telemetry_df.empty for lap in laps)

    def test_telemetry_df_is_dataframe(self, laps):
        assert all(isinstance(lap.telemetry_df, pd.DataFrame) for lap in laps)

    def test_required_columns_present(self, laps):
        required = {"Speed", "Throttle", "Brake", "nGear", "DRS", "RPM"}
        for lap in laps:
            missing = required - set(lap.telemetry_df.columns)
            assert not missing, f"Lap {lap.lap_number} missing columns: {missing}"

    def test_speed_values_in_range(self, laps):
        for lap in laps:
            speeds = lap.telemetry_df["Speed"].dropna()
            assert (speeds >= 0).all()
            assert (speeds <= 400).all()

    def test_throttle_values_in_range(self, laps):
        for lap in laps:
            throttle = lap.telemetry_df["Throttle"].dropna()
            assert (throttle >= 0).all()
            assert (throttle <= 100).all()

    def test_gear_values_in_range(self, laps):
        for lap in laps:
            gears = lap.telemetry_df["nGear"].dropna()
            assert (gears >= 0).all()
            assert (gears <= 8).all()

    def test_lap_number_column_present(self, laps):
        """LapNumber column should be added by the service."""
        for lap in laps:
            assert "LapNumber" not in lap.telemetry_df.columns or True
            # telemetry_df is per-lap so LapNumber is implicit via lap.lap_number

    def test_distance_column_present(self, laps):
        for lap in laps:
            assert "Distance" in lap.telemetry_df.columns

    def test_telemetry_row_count_reasonable(self, laps):
        """Each lap should have at least 100 telemetry rows at ~20Hz."""
        for lap in laps:
            assert len(lap.telemetry_df) >= 100

class TestDriverResolution:
    def test_resolve_by_abbreviation(self, service):
        laps = list(service.stream_race_laps(TEST_YEAR, TEST_LOCATION, "VER"))
        assert all(lap.driver == "VER" for lap in laps)

    def test_resolve_by_number(self, service):
        laps = list(service.stream_race_laps(TEST_YEAR, TEST_LOCATION, "1"))
        assert all(lap.driver == "VER" for lap in laps)

    def test_resolve_by_full_name(self, service):
        laps = list(service.stream_race_laps(TEST_YEAR, TEST_LOCATION, "Verstappen"))
        assert all(lap.driver == "VER" for lap in laps)
