import pandas as pd
import os
from pathlib import Path
from typing import List, Optional, Generator
from models.commentary_models import TelemetryData


CSV_TO_MODEL_MAPPING = {
    # Required fields
    "Time (s)": "time",
    "Position": "position",
    "Ground Speed (km/h)": "ground_speed",
    "Engine RPM (rpm)": "engine_rpm",
    "Gear": "gear",
    "Throttle Pos (%)": "throttle_pos",
    "Brake Pos (%)": "brake_pos",
    "Steering Angle (deg)": "steering_angle",
    "Lap Time (s)": "lap_time",
    
}

class CSVTelemetryService:
    
    def __init__(self, csv_path: str):

        self.csv_path = csv_path
        self.df = pd.read_csv(csv_path)
        self.total_rows = len(self.df)
    
    def _map_row_to_telemetry(self, row: pd.Series) -> TelemetryData:

        # Build dictionary with mapped field names
        telem_dict = {}
        
        bool_fields = ["lap_invalidated", "tc_active", "abs_active"]
        
        int_fields = ["gear", "position", "session_lap_count", "num_tires_off_track", "engine_rpm"]
        
        for csv_col, model_field in CSV_TO_MODEL_MAPPING.items():
            if csv_col in row.index:
                value = row[csv_col]
                
                if pd.isna(value):
                    telem_dict[model_field] = None
                else:

                    if model_field in bool_fields:
                        telem_dict[model_field] = bool(value)

                    elif model_field in int_fields:
                        telem_dict[model_field] = int(value)
                    else:
                        telem_dict[model_field] = value
        
        return TelemetryData(**telem_dict)
    
    def get_telemetry_at_time(self, time_seconds: float) -> Optional[TelemetryData]:

        # Find the row with the closest time value
        closest_idx = (self.df["Time (s)"] - time_seconds).abs().idxmin()
        row = self.df.iloc[closest_idx]
        
        return self._map_row_to_telemetry(row)
    
    
    def get_all_telemetry(self) -> List[TelemetryData]:
        """
        Convert entire CSV to a list of TelemetryData objects
        
        Returns:
            List of all telemetry data points
        """
        telemetry_list = []
        for _, row in self.df.iterrows():
            telemetry_list.append(self._map_row_to_telemetry(row))
        
        return telemetry_list
    
    def stream_telemetry(self, start_index: int = 0, end_index: Optional[int] = None) -> Generator[TelemetryData, None, None]:
        if end_index is None:
            end_index = self.total_rows
        
        for i in range(start_index, min(end_index, self.total_rows)):
            yield self._map_row_to_telemetry(self.df.iloc[i])
    
    def get_telemetry_count(self) -> int:
        return self.total_rows
    
    def get_time_range(self) -> tuple[float, float]:
        if "Time (s)" in self.df.columns:
            return (self.df["Time (s)"].min(), self.df["Time (s)"].max())
        return (0.0, 0.0)



def list_available_csvs(directory: str) -> List[str]:
    csv_files = []
    path = Path(directory)
    
    if path.exists() and path.is_dir():
        csv_files = [f.name for f in path.glob("*.csv") if not f.name.endswith("Meta.csv")]
    
    return csv_files

def parse_csv_metadata(csv_filename: str, csv_directory: str) -> dict:
    """Read metadata from Meta.csv file"""
    base_name = csv_filename.replace(".csv", "")
    meta_path = os.path.join(csv_directory, f"{base_name}Meta.csv")
    
    if os.path.exists(meta_path):
        meta_df = pd.read_csv(meta_path)
        return {
            "venue": meta_df['Venue'].iloc[0],      
            "vehicle": meta_df['Vehicle'].iloc[0],  
            "date": meta_df['Log Date'].iloc[0],
            "time": meta_df['Log Time'].iloc[0],
            "duration": meta_df['Duration'].iloc[0],
            "sample_rate": meta_df['Sample Rate'].iloc[0]
        }
    else:
        # Fallback to filename parsing
        return parse_csv_filename(csv_filename)


def parse_csv_filename(filename: str) -> dict:

    name = filename.replace(".csv", "")
    
    # Split by underscore
    parts = name.split("_")
    
    if len(parts) >= 3:
        time = parts[-1]
        date = parts[-2]
        remaining = parts[:-2]
        
        # Split remaining parts roughly in half
        # For "ks_brands_hatch_ac_legends_bmw_csl" -> 6 parts
        # First 3: venue (ks_brands_hatch)
        # Last 3: vehicle (ac_legends_bmw_csl)
        split_point = len(remaining) // 2
        
        venue_parts = remaining[:split_point] if split_point > 0 else remaining
        vehicle_parts = remaining[split_point:] if split_point > 0 else []
        
        venue = "_".join(venue_parts) if venue_parts else "unknown"
        vehicle = "_".join(vehicle_parts) if vehicle_parts else "unknown"
        
        return {
            "venue": venue,
            "vehicle": vehicle,
            "date": date,
            "time": time
        }
    
    return {
        "venue": "unknown",
        "vehicle": "unknown",
        "date": "unknown",
        "time": "unknown"
    }
