# CSV Telemetry Service Step 1 Map

Target file: `backend/fast_app/services/csv_telemetry_service.py`

## Public API surface

- `CSVTelemetryService.__init__(csv_path)`
- `CSVTelemetryService.get_telemetry_at_time(time_seconds)`
- `CSVTelemetryService.get_all_telemetry()`
- `CSVTelemetryService.stream_telemetry(start_index=0, end_index=None)`
- `CSVTelemetryService.get_telemetry_count()`
- `CSVTelemetryService.get_time_range()`
- `list_available_csvs(directory)`
- `parse_csv_metadata(csv_filename, csv_directory)`
- `parse_csv_filename(filename)`

## Internal helper

- `CSVTelemetryService._map_row_to_telemetry(row)`

## Dependencies and assumptions

- Uses `pd.read_csv` directly in constructor.
- Expects required telemetry columns from `CSV_TO_MODEL_MAPPING` to exist for meaningful output.
- Does not currently validate CSV schema before use.
- `get_telemetry_at_time` assumes `self.df["Time (s)"]` exists.

## Key data mapping behavior

- Mapping source: `CSV_TO_MODEL_MAPPING`
- NaN values are mapped to `None`.
- Integer cast attempted for:
  - `gear`, `position`, `session_lap_count`, `num_tires_off_track`, `engine_rpm`
- Boolean cast path exists for:
  - `lap_invalidated`, `tc_active`, `abs_active`
- Current mapping table does not include those bool/int extras except `gear`, `position`, `engine_rpm`.

## Branch and risk points for future tests

- Constructor:
  - `pd.read_csv` success
  - `pd.read_csv` failure path bubbling

- `_map_row_to_telemetry`:
  - mapped column present vs missing
  - value is `NaN` -> `None`
  - integer cast paths (`gear`, `position`, `engine_rpm`)

- `get_telemetry_at_time`:
  - nearest index selection for in-range and out-of-range times
  - missing `"Time (s)"` column failure behavior

- `stream_telemetry`:
  - `end_index=None` default range
  - `end_index > total_rows` clamped behavior
  - `start_index` at boundary values

- `get_time_range`:
  - `"Time (s)"` present returns `(min, max)`
  - missing time column returns `(0.0, 0.0)`

- `list_available_csvs`:
  - existing directory includes only `*.csv`
  - excludes `*Meta.csv`
  - missing/non-dir returns empty list

- `parse_csv_metadata`:
  - meta file exists and fields parsed
  - meta file missing falls back to `parse_csv_filename`

- `parse_csv_filename`:
  - filename with expected underscore pattern
  - shorter/unexpected format returns `unknown` defaults
