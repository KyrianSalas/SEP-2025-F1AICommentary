#!/usr/bin/env python3
"""
f1_fastf1_track_demo.py

An advanced F1 telemetry visualization tool using FastF1.
Features interactive session/driver selection, multi-panel telemetry dashboard,
and animated track visualization with speed-coloured traces.

Usage:
    python f1_fastf1_track_demo.py

Dependencies:
    pip install fastf1 matplotlib numpy

First run may take longer as data is downloaded from FastF1's API.
Subsequent runs use the local cache at ./f1cache for faster loading.
"""

import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass

import numpy as np

try:
    import fastf1
    import fastf1.core
except ImportError:
    print("ERROR: fastf1 not installed. Run: pip install fastf1")
    sys.exit(1)


# =============================================================================
# COLOUR SCHEME - Racing-inspired dark theme
# =============================================================================
COLORS = {
    'background': '#1a1a2e',
    'panel_bg': '#16213e',
    'grid': '#0f3460',
    'text': '#e8e8e8',
    'accent': '#e94560',
    'secondary': '#00d9ff',
    'throttle': '#00ff88',
    'brake': '#ff4444',
    'speed': '#ffd700',
    'rpm': '#ff6b35',
    'gear': '#4ecdc4',
    'drs': '#9b59b6',
}

# F1 Team colours for 2024
TEAM_COLORS = {
    'Red Bull Racing': '#3671C6',
    'Ferrari': '#E80020',
    'Mercedes': '#27F4D2',
    'McLaren': '#FF8000',
    'Aston Martin': '#229971',
    'Alpine': '#FF87BC',
    'Williams': '#64C4FF',
    'AlphaTauri': '#6692FF',
    'RB': '#6692FF',
    'Alfa Romeo': '#C92D4B',
    'Kick Sauber': '#52E252',
    'Haas F1 Team': '#B6BABD',
}


@dataclass
class TelemetryData:
    """Container for extracted telemetry data from a lap."""
    time: np.ndarray
    distance: np.ndarray
    x: np.ndarray
    y: np.ndarray
    speed: np.ndarray
    throttle: np.ndarray
    brake: np.ndarray
    rpm: np.ndarray
    gear: np.ndarray
    drs: np.ndarray
    driver: str
    team: str
    lap_number: int
    lap_time: Optional[str]


def enable_cache() -> str:
    """
    Enable FastF1 cache for faster subsequent data loading.
    
    Returns:
        str: Path to the cache directory
    """
    cache_path = "./f1cache"
    Path(cache_path).mkdir(parents=True, exist_ok=True)
    fastf1.Cache.enable_cache(cache_path)
    return cache_path


def get_available_seasons() -> List[int]:
    """
    Get list of available F1 seasons with telemetry data.
    
    Returns:
        List[int]: Available seasons (FastF1 has data from 2018+)
    """
    return list(range(2025, 2017, -1))


def get_season_schedule(year: int) -> List[Dict]:
    """
    Fetch the race schedule for a given season.
    
    Args:
        year: Season year
        
    Returns:
        List[Dict]: List of events with name and round number
    """
    try:
        schedule = fastf1.get_event_schedule(year)
        events = []
        for idx, row in schedule.iterrows():
            if row['EventFormat'] != 'testing':
                events.append({
                    'round': row['RoundNumber'],
                    'name': row['EventName'],
                    'location': row['Location'],
                    'country': row['Country'],
                })
        return events
    except Exception as e:
        print(f"[ERROR] Failed to get schedule: {e}")
        return []


def get_session_drivers(session: fastf1.core.Session) -> List[Dict]:
    """
    Get list of drivers who participated in a session.
    
    Args:
        session: Loaded FastF1 session
        
    Returns:
        List[Dict]: Driver info with code, name, and team
    """
    drivers = []
    try:
        for drv in session.drivers:
            driver_info = session.get_driver(drv)
            drivers.append({
                'code': driver_info['Abbreviation'],
                'name': f"{driver_info['FirstName']} {driver_info['LastName']}",
                'team': driver_info['TeamName'],
                'number': driver_info['DriverNumber'],
            })
    except Exception as e:
        print(f"[WARN] Error getting driver info: {e}")
    return drivers


def load_session(year: int, gp: str, session_type: str) -> Optional[fastf1.core.Session]:
    """
    Load a FastF1 session with full telemetry data.
    
    Args:
        year: Season year
        gp: Grand Prix name or round number
        session_type: Session identifier (R, Q, FP1, FP2, FP3, S, SQ)
        
    Returns:
        Loaded session object or None on failure
    """
    enable_cache()
    print(f"[INFO] Loading session: {year} {gp} ({session_type})")
    
    try:
        session = fastf1.get_session(year, gp, session_type)
        session.load()
        print(f"[INFO] Session loaded: {session.event['EventName']} - {session.name}")
        return session
    except Exception as e:
        print(f"[ERROR] Failed to load session: {e}")
        return None


def extract_telemetry(lap: fastf1.core.Lap, driver_info: Dict) -> Optional[TelemetryData]:
    """
    Extract comprehensive telemetry data from a lap.
    
    FastF1 provides various telemetry channels:
    - Speed: km/h
    - Throttle: 0-100%
    - Brake: 0-100 (or boolean in some sessions)
    - RPM: Engine revolutions per minute
    - nGear: Current gear (0-8)
    - DRS: DRS activation status
    - X, Y: Track position in metres
    - Distance: Cumulative distance in metres
    
    Args:
        lap: FastF1 Lap object
        driver_info: Dict with driver code and team
        
    Returns:
        TelemetryData object or None on failure
    """
    try:
        tel = lap.get_telemetry()
        
        if tel.empty or len(tel) < 2:
            print("[WARN] Telemetry is empty or too short")
            return None
        
        # Time in seconds
        time = tel['Time'].dt.total_seconds().to_numpy()
        
        # Distance
        distance = tel['Distance'].to_numpy() if 'Distance' in tel.columns else np.arange(len(tel))
        
        # Position
        x = tel['X'].to_numpy() if 'X' in tel.columns else np.zeros(len(tel))
        y = tel['Y'].to_numpy() if 'Y' in tel.columns else np.zeros(len(tel))
        
        # Speed
        speed = tel['Speed'].to_numpy() if 'Speed' in tel.columns else np.zeros(len(tel))
        
        # Throttle (0-100)
        throttle = tel['Throttle'].to_numpy() if 'Throttle' in tel.columns else np.zeros(len(tel))
        
        # Brake (can be 0-100 or boolean)
        if 'Brake' in tel.columns:
            brake = tel['Brake'].to_numpy()
            # Convert boolean to percentage if needed
            if brake.dtype == bool:
                brake = brake.astype(float) * 100
        else:
            brake = np.zeros(len(tel))
        
        # RPM
        rpm = tel['RPM'].to_numpy() if 'RPM' in tel.columns else np.zeros(len(tel))
        
        # Gear
        gear = tel['nGear'].to_numpy() if 'nGear' in tel.columns else np.zeros(len(tel))
        
        # DRS
        if 'DRS' in tel.columns:
            drs = tel['DRS'].to_numpy()
        else:
            drs = np.zeros(len(tel))
        
        # Format lap time
        lap_time = None
        if hasattr(lap, 'LapTime') and lap['LapTime'] is not None:
            try:
                total_seconds = lap['LapTime'].total_seconds()
                mins = int(total_seconds // 60)
                secs = total_seconds % 60
                lap_time = f"{mins}:{secs:06.3f}"
            except:
                pass
        
        return TelemetryData(
            time=time,
            distance=distance,
            x=x,
            y=y,
            speed=speed,
            throttle=throttle,
            brake=brake,
            rpm=rpm,
            gear=gear,
            drs=drs,
            driver=driver_info.get('code', 'UNK'),
            team=driver_info.get('team', 'Unknown'),
            lap_number=int(lap['LapNumber']) if 'LapNumber' in lap.index else 0,
            lap_time=lap_time,
        )
    except Exception as e:
        print(f"[ERROR] Failed to extract telemetry: {e}")
        return None


def get_driver_fastest_lap(session: fastf1.core.Session, driver_code: str) -> Optional[fastf1.core.Lap]:
    """
    Get the fastest lap for a specific driver in a session.
    
    Args:
        session: Loaded FastF1 session
        driver_code: 3-letter driver code
        
    Returns:
        Fastest lap object or None
    """
    try:
        driver_laps = session.laps.pick_driver(driver_code)
        if driver_laps.empty:
            return None
        
        fastest = driver_laps.pick_fastest()
        if fastest is not None and not fastest.empty:
            return fastest
        
        # Fallback to first lap
        return driver_laps.iloc[0]
    except Exception as e:
        print(f"[ERROR] Could not get lap for {driver_code}: {e}")
        return None


def print_available_telemetry_channels():
    """Print the available telemetry data channels from FastF1."""
    channels = [
        ("Speed", "km/h", "Vehicle speed"),
        ("Throttle", "0-100%", "Throttle pedal position"),
        ("Brake", "0-100%", "Brake pedal pressure"),
        ("RPM", "rev/min", "Engine revolutions per minute"),
        ("nGear", "1-8", "Current gear selection"),
        ("DRS", "0/1", "DRS activation status"),
        ("X", "metres", "Track X position"),
        ("Y", "metres", "Track Y position"),
        ("Distance", "metres", "Cumulative lap distance"),
    ]
    print("\n[INFO] Available FastF1 Telemetry Channels:")
    print("-" * 50)
    for name, unit, desc in channels:
        print(f"  {name:12} [{unit:8}] - {desc}")
    print("-" * 50)


if __name__ == "__main__":
    # Initialize cache
    cache_dir = enable_cache()
    print(f"[INFO] FastF1 cache enabled at: {cache_dir}")
    print_available_telemetry_channels()
    
    print("\n" + "="*50)
    print("  FastF1 Telemetry Data Module")
    print("="*50)
    print("\nThis is the core data module. To run the full app:")
    print("  python main.py")
    print("\nAvailable modules:")
    print("  - main.py             : Full interactive application")
    print("  - gui_selector.py     : Session/driver selection GUI")
    print("  - telemetry_visualizer.py : Multi-panel dashboard")
    print("  - track_animation.py  : Animated track visualization")
    print("  - driver_comparison.py: Head-to-head comparison")
    print("  - sector_analysis.py  : Mini-sector breakdown")
    print("  - lap_statistics.py   : Performance statistics")
    print("="*50)
