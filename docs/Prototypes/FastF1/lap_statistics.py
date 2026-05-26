#!/usr/bin/env python3
"""
lap_statistics.py

Calculate and display comprehensive lap statistics.
Provides summary metrics and performance indicators.
"""

import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch
from typing import List, Optional

from f1_fastf1_track_demo import (
    COLORS,
    TEAM_COLORS,
    TelemetryData,
    extract_telemetry,
    get_driver_fastest_lap,
)


def calculate_lap_stats(telemetry: TelemetryData) -> dict:
    """
    Calculate comprehensive statistics from lap telemetry.
    
    Args:
        telemetry: TelemetryData object
        
    Returns:
        Dict containing various performance metrics
    """
    speed = telemetry.speed
    throttle = telemetry.throttle
    brake = telemetry.brake
    rpm = telemetry.rpm
    gear = telemetry.gear
    drs = telemetry.drs
    distance = telemetry.distance
    
    # Speed statistics
    speed_stats = {
        'max': float(np.max(speed)),
        'min': float(np.min(speed)),
        'avg': float(np.mean(speed)),
        'std': float(np.std(speed)),
    }
    
    # Throttle application
    full_throttle_mask = throttle >= 95
    partial_throttle_mask = (throttle > 5) & (throttle < 95)
    off_throttle_mask = throttle <= 5
    
    throttle_stats = {
        'full_throttle_pct': float(np.sum(full_throttle_mask) / len(throttle) * 100),
        'partial_pct': float(np.sum(partial_throttle_mask) / len(throttle) * 100),
        'off_throttle_pct': float(np.sum(off_throttle_mask) / len(throttle) * 100),
        'avg': float(np.mean(throttle)),
    }
    
    # Braking zones
    braking_mask = brake > 10
    brake_stats = {
        'time_braking_pct': float(np.sum(braking_mask) / len(brake) * 100),
        'max_brake': float(np.max(brake)),
        'avg_when_braking': float(np.mean(brake[braking_mask])) if np.any(braking_mask) else 0,
        'num_brake_zones': count_brake_zones(brake),
    }
    
    # RPM statistics
    rpm_stats = {
        'max': float(np.max(rpm)),
        'min': float(np.min(rpm[rpm > 0])) if np.any(rpm > 0) else 0,
        'avg': float(np.mean(rpm)),
        'time_above_10k': float(np.sum(rpm > 10000) / len(rpm) * 100),
    }
    
    # Gear usage
    gear_counts = {}
    for g in range(0, 9):
        gear_counts[g] = float(np.sum(gear == g) / len(gear) * 100)
    
    gear_stats = {
        'usage_by_gear': gear_counts,
        'avg_gear': float(np.mean(gear)),
        'upshifts': count_gear_changes(gear, direction='up'),
        'downshifts': count_gear_changes(gear, direction='down'),
    }
    
    # DRS usage
    drs_active = drs > 0
    drs_stats = {
        'time_active_pct': float(np.sum(drs_active) / len(drs) * 100),
        'activations': count_drs_activations(drs),
    }
    
    # Distance and lap info
    lap_stats = {
        'total_distance': float(distance.max() - distance.min()),
        'lap_time': telemetry.lap_time,
        'lap_number': telemetry.lap_number,
        'driver': telemetry.driver,
        'team': telemetry.team,
    }
    
    return {
        'speed': speed_stats,
        'throttle': throttle_stats,
        'brake': brake_stats,
        'rpm': rpm_stats,
        'gear': gear_stats,
        'drs': drs_stats,
        'lap': lap_stats,
    }


def count_brake_zones(brake: np.ndarray, threshold: float = 10) -> int:
    """Count distinct braking zones."""
    braking = brake > threshold
    # Count transitions from not-braking to braking
    transitions = np.diff(braking.astype(int))
    return int(np.sum(transitions == 1))


def count_gear_changes(gear: np.ndarray, direction: str = 'up') -> int:
    """Count gear changes in specified direction."""
    diffs = np.diff(gear)
    if direction == 'up':
        return int(np.sum(diffs > 0))
    else:
        return int(np.sum(diffs < 0))


def count_drs_activations(drs: np.ndarray) -> int:
    """Count DRS activation events."""
    active = drs > 0
    transitions = np.diff(active.astype(int))
    return int(np.sum(transitions == 1))


class LapStatsDisplay:
    """
    Visual display of lap statistics in a dashboard format.
    """
    
    def __init__(self, telemetry: TelemetryData):
        self.telemetry = telemetry
        self.stats = calculate_lap_stats(telemetry)
        self.fig = None
        
        team_color = TEAM_COLORS.get(telemetry.team, COLORS['accent'])
        self.driver_color = team_color
    
    def create_display(self, figsize=(14, 10)):
        """Create the statistics display figure."""
        self.fig = plt.figure(figsize=figsize, facecolor=COLORS['background'])
        
        # Create custom layout
        self._draw_header()
        self._draw_speed_panel()
        self._draw_inputs_panel()
        self._draw_gear_panel()
        self._draw_summary_panel()
        
        return self.fig
    
    def _draw_header(self):
        """Draw the header with driver info."""
        ax = self.fig.add_axes([0.02, 0.88, 0.96, 0.1])
        ax.set_facecolor(COLORS['panel_bg'])
        ax.set_xlim(0, 10)
        ax.set_ylim(0, 1)
        ax.axis('off')
        
        for spine in ax.spines.values():
            spine.set_visible(False)
        
        # Driver info
        driver = self.stats['lap']['driver']
        team = self.stats['lap']['team']
        lap_time = self.stats['lap']['lap_time'] or "N/A"
        lap_num = self.stats['lap']['lap_number']
        
        ax.text(0.2, 0.5, driver, fontsize=36, fontweight='bold',
               color=self.driver_color, va='center')
        ax.text(2.5, 0.5, f"Lap {lap_num}", fontsize=18,
               color=COLORS['text'], va='center')
        
        # Lap time prominent
        ax.text(8, 0.5, lap_time, fontsize=32, fontweight='bold',
               color=COLORS['accent'], va='center', ha='right')
        ax.text(8.2, 0.5, "LAP TIME", fontsize=10,
               color=COLORS['text'], va='center', alpha=0.7)
    
    def _draw_speed_panel(self):
        """Draw speed statistics panel."""
        ax = self.fig.add_axes([0.02, 0.55, 0.46, 0.30])
        ax.set_facecolor(COLORS['panel_bg'])
        ax.set_xlim(0, 10)
        ax.set_ylim(0, 10)
        ax.axis('off')
        
        for spine in ax.spines.values():
            spine.set_color(COLORS['grid'])
        
        ax.text(5, 9, "SPEED ANALYSIS", ha='center', fontsize=14,
               color=COLORS['text'], fontweight='bold')
        
        stats = self.stats['speed']
        items = [
            (f"{stats['max']:.0f}", "MAX km/h", COLORS['accent']),
            (f"{stats['avg']:.0f}", "AVG km/h", COLORS['secondary']),
            (f"{stats['min']:.0f}", "MIN km/h", COLORS['throttle']),
        ]
        
        for i, (value, label, color) in enumerate(items):
            x = 1.5 + i * 3
            ax.text(x, 5.5, value, fontsize=28, fontweight='bold',
                   color=color, ha='center')
            ax.text(x, 3.5, label, fontsize=10, color=COLORS['text'],
                   ha='center', alpha=0.8)
    
    def _draw_inputs_panel(self):
        """Draw throttle/brake statistics panel."""
        ax = self.fig.add_axes([0.52, 0.55, 0.46, 0.30])
        ax.set_facecolor(COLORS['panel_bg'])
        ax.set_xlim(0, 10)
        ax.set_ylim(0, 10)
        ax.axis('off')
        
        ax.text(5, 9, "DRIVER INPUTS", ha='center', fontsize=14,
               color=COLORS['text'], fontweight='bold')
        
        throttle = self.stats['throttle']
        brake = self.stats['brake']
        
        # Throttle stats
        ax.text(2.5, 6.5, f"{throttle['full_throttle_pct']:.1f}%", 
               fontsize=24, fontweight='bold', color=COLORS['throttle'], ha='center')
        ax.text(2.5, 5, "FULL THROTTLE", fontsize=9, color=COLORS['text'], 
               ha='center', alpha=0.8)
        
        # Brake stats
        ax.text(7.5, 6.5, f"{brake['time_braking_pct']:.1f}%",
               fontsize=24, fontweight='bold', color=COLORS['brake'], ha='center')
        ax.text(7.5, 5, "BRAKING", fontsize=9, color=COLORS['text'],
               ha='center', alpha=0.8)
        
        # Brake zones count
        ax.text(5, 2.5, f"{brake['num_brake_zones']}", fontsize=20,
               fontweight='bold', color=COLORS['text'], ha='center')
        ax.text(5, 1.5, "BRAKE ZONES", fontsize=9, color=COLORS['text'],
               ha='center', alpha=0.8)
    
    def _draw_gear_panel(self):
        """Draw gear usage panel."""
        ax = self.fig.add_axes([0.02, 0.15, 0.46, 0.35])
        ax.set_facecolor(COLORS['panel_bg'])
        
        ax.set_title("GEAR USAGE %", fontsize=12, color=COLORS['text'],
                    fontweight='bold', pad=10)
        
        gear_usage = self.stats['gear']['usage_by_gear']
        gears = list(range(1, 9))
        usage = [gear_usage.get(g, 0) for g in gears]
        
        colors = plt.cm.viridis(np.linspace(0.2, 0.9, len(gears)))
        
        bars = ax.bar(gears, usage, color=colors, edgecolor=COLORS['grid'])
        
        ax.set_xlabel('Gear', color=COLORS['text'])
        ax.set_ylabel('Usage %', color=COLORS['text'])
        ax.set_xticks(gears)
        ax.tick_params(colors=COLORS['text'])
        
        for spine in ax.spines.values():
            spine.set_color(COLORS['grid'])
        
        ax.grid(True, alpha=0.15, color=COLORS['grid'], axis='y')
        
        # Add shift counts
        upshifts = self.stats['gear']['upshifts']
        downshifts = self.stats['gear']['downshifts']
        ax.text(0.98, 0.95, f"↑{upshifts} shifts  ↓{downshifts} shifts",
               transform=ax.transAxes, ha='right', va='top',
               fontsize=9, color=COLORS['text'])
    
    def _draw_summary_panel(self):
        """Draw summary statistics panel."""
        ax = self.fig.add_axes([0.52, 0.15, 0.46, 0.35])
        ax.set_facecolor(COLORS['panel_bg'])
        ax.set_xlim(0, 10)
        ax.set_ylim(0, 10)
        ax.axis('off')
        
        for spine in ax.spines.values():
            spine.set_color(COLORS['grid'])
        
        ax.text(5, 9, "SESSION METRICS", ha='center', fontsize=12,
               color=COLORS['text'], fontweight='bold')
        
        rpm = self.stats['rpm']
        drs = self.stats['drs']
        lap = self.stats['lap']
        
        metrics = [
            (f"{rpm['max']:.0f}", "MAX RPM", COLORS['rpm']),
            (f"{rpm['time_above_10k']:.1f}%", "TIME > 10K RPM", COLORS['rpm']),
            (f"{drs['time_active_pct']:.1f}%", "DRS ACTIVE", COLORS['drs']),
            (f"{drs['activations']}", "DRS ACTIVATIONS", COLORS['drs']),
            (f"{lap['total_distance']/1000:.2f} km", "LAP DISTANCE", COLORS['secondary']),
        ]
        
        for i, (value, label, color) in enumerate(metrics):
            y = 7.5 - i * 1.4
            ax.text(1, y, label, fontsize=10, color=COLORS['text'], alpha=0.8)
            ax.text(9, y, value, fontsize=14, fontweight='bold',
                   color=color, ha='right')
    
    def show(self):
        """Display the statistics."""
        plt.show()


def show_lap_stats(session, driver_code: str, drivers_info: List[dict]):
    """
    Display lap statistics for a driver.
    
    Args:
        session: Loaded FastF1 session
        driver_code: 3-letter driver code
        drivers_info: List of driver info dicts
    """
    driver_info = {}
    for d in drivers_info:
        if d['code'] == driver_code:
            driver_info = d
            break
    
    if not driver_info:
        driver_info = {'code': driver_code, 'team': 'Unknown'}
    
    lap = get_driver_fastest_lap(session, driver_code)
    if lap is None:
        print(f"[ERROR] No lap found for {driver_code}")
        return None
    
    telemetry = extract_telemetry(lap, driver_info)
    if telemetry is None:
        print(f"[ERROR] Failed to extract telemetry for {driver_code}")
        return None
    
    display = LapStatsDisplay(telemetry)
    display.create_display()
    display.show()
    
    return display


if __name__ == "__main__":
    print("[INFO] Lap statistics module loaded")
    print("[INFO] Use show_lap_stats(session, driver_code, drivers_info) to display")

