#!/usr/bin/env python3
"""
driver_comparison.py

Compare telemetry data between two or more drivers.
Visualizes differences in driving style, speed, and performance.
"""

import numpy as np
import matplotlib.pyplot as plt
from matplotlib.gridspec import GridSpec
from typing import List, Optional, Tuple

from f1_fastf1_track_demo import (
    COLORS,
    TEAM_COLORS,
    TelemetryData,
    extract_telemetry,
    get_driver_fastest_lap,
)


class DriverComparison:
    """
    Compare telemetry between multiple drivers on the same lap/session.
    
    Creates visualizations showing:
    - Speed delta between drivers
    - Overlaid throttle/brake traces
    - Sector-by-sector analysis
    - Track position comparison
    """
    
    def __init__(self, telemetry_list: List[TelemetryData]):
        self.telemetry_list = telemetry_list
        self.fig = None
        self.axes = {}
        
        # Assign colors
        self.driver_colors = {}
        for tel in telemetry_list:
            team_color = TEAM_COLORS.get(tel.team, None)
            if team_color and team_color not in self.driver_colors.values():
                self.driver_colors[tel.driver] = team_color
            else:
                # Fallback colors
                fallback = [COLORS['accent'], COLORS['secondary'], 
                           COLORS['throttle'], COLORS['rpm']]
                idx = len(self.driver_colors) % len(fallback)
                self.driver_colors[tel.driver] = fallback[idx]
    
    def _apply_style(self, ax, title: str = ""):
        """Apply dark theme styling."""
        ax.set_facecolor(COLORS['panel_bg'])
        ax.tick_params(colors=COLORS['text'], labelsize=9)
        
        if title:
            ax.set_title(title, color=COLORS['text'], fontsize=11, 
                        fontweight='bold', pad=10)
        
        for spine in ax.spines.values():
            spine.set_color(COLORS['grid'])
        
        ax.grid(True, alpha=0.15, color=COLORS['grid'])
    
    def create_comparison(self, figsize: Tuple[int, int] = (16, 12)):
        """Create the comparison figure layout."""
        self.fig = plt.figure(figsize=figsize, facecolor=COLORS['background'])
        
        # Grid: 5 rows, 2 columns
        gs = GridSpec(5, 2, figure=self.fig, 
                      hspace=0.35, wspace=0.25,
                      height_ratios=[1, 0.6, 1, 1, 0.8])
        
        # Speed comparison (top, full width)
        self.axes['speed'] = self.fig.add_subplot(gs[0, :])
        
        # Time delta (second row, full width)
        self.axes['time_delta'] = self.fig.add_subplot(gs[1, :])
        
        # Speed delta (third row, full width)
        self.axes['delta'] = self.fig.add_subplot(gs[2, :])
        
        # Throttle (left)
        self.axes['throttle'] = self.fig.add_subplot(gs[3, 0])
        
        # Brake (right)
        self.axes['brake'] = self.fig.add_subplot(gs[3, 1])
        
        # Track comparison (bottom, full width)
        self.axes['track'] = self.fig.add_subplot(gs[4, :])
        
        # Title
        drivers = [t.driver for t in self.telemetry_list]
        title = " vs ".join(drivers) + " - Fastest Lap Comparison"
        self.fig.suptitle(title, fontsize=16, color=COLORS['text'], 
                         fontweight='bold', y=0.98)
        
        return self.fig
    
    def _interpolate_to_distance(self, tel: TelemetryData, 
                                  target_distance: np.ndarray) -> dict:
        """
        Interpolate telemetry data to a common distance basis.
        
        Args:
            tel: TelemetryData object
            target_distance: Common distance array for interpolation
            
        Returns:
            Dict of interpolated arrays
        """
        return {
            'speed': np.interp(target_distance, tel.distance, tel.speed),
            'throttle': np.interp(target_distance, tel.distance, tel.throttle),
            'brake': np.interp(target_distance, tel.distance, tel.brake),
            'rpm': np.interp(target_distance, tel.distance, tel.rpm),
            'gear': np.interp(target_distance, tel.distance, tel.gear),
            'x': np.interp(target_distance, tel.distance, tel.x),
            'y': np.interp(target_distance, tel.distance, tel.y),
            'time': np.interp(target_distance, tel.distance, tel.time),
        }
    
    def plot_speed_comparison(self):
        """Plot overlaid speed traces for all drivers."""
        ax = self.axes['speed']
        self._apply_style(ax, "Speed Comparison")
        
        for tel in self.telemetry_list:
            color = self.driver_colors[tel.driver]
            label = f"{tel.driver} ({tel.lap_time or 'N/A'})"
            ax.plot(tel.distance, tel.speed, color=color, 
                   linewidth=1.5, label=label, alpha=0.9)
        
        ax.set_xlabel('Distance (m)', color=COLORS['text'])
        ax.set_ylabel('Speed (km/h)', color=COLORS['text'])
        ax.legend(loc='upper right', fontsize=9, facecolor=COLORS['panel_bg'],
                  edgecolor=COLORS['grid'], labelcolor=COLORS['text'])
    
    def plot_speed_delta(self):
        """
        Plot speed delta between first two drivers.
        
        Positive values = first driver faster
        Negative values = second driver faster
        """
        ax = self.axes['delta']
        self._apply_style(ax, "Speed Delta (First - Second Driver)")
        
        if len(self.telemetry_list) < 2:
            ax.text(0.5, 0.5, "Need 2+ drivers for delta", 
                   transform=ax.transAxes, ha='center', va='center',
                   color=COLORS['text'])
            return
        
        tel1 = self.telemetry_list[0]
        tel2 = self.telemetry_list[1]
        
        # Create common distance basis
        min_dist = max(tel1.distance.min(), tel2.distance.min())
        max_dist = min(tel1.distance.max(), tel2.distance.max())
        common_distance = np.linspace(min_dist, max_dist, 1000)
        
        # Interpolate speeds
        speed1 = np.interp(common_distance, tel1.distance, tel1.speed)
        speed2 = np.interp(common_distance, tel2.distance, tel2.speed)
        delta = speed1 - speed2
        
        # Color positive/negative differently
        ax.fill_between(common_distance, 0, delta, 
                        where=delta >= 0, alpha=0.6,
                        color=self.driver_colors[tel1.driver],
                        label=f'{tel1.driver} faster')
        ax.fill_between(common_distance, 0, delta,
                        where=delta < 0, alpha=0.6,
                        color=self.driver_colors[tel2.driver],
                        label=f'{tel2.driver} faster')
        
        ax.axhline(y=0, color=COLORS['text'], linewidth=0.5, alpha=0.5)
        
        ax.set_xlabel('Distance (m)', color=COLORS['text'])
        ax.set_ylabel('Speed Delta (km/h)', color=COLORS['text'])
        ax.legend(loc='upper right', fontsize=9, facecolor=COLORS['panel_bg'],
                  edgecolor=COLORS['grid'], labelcolor=COLORS['text'])
    
    def plot_throttle_comparison(self):
        """Plot overlaid throttle traces."""
        ax = self.axes['throttle']
        self._apply_style(ax, "Throttle Application")
        
        for tel in self.telemetry_list:
            color = self.driver_colors[tel.driver]
            ax.plot(tel.distance, tel.throttle, color=color,
                   linewidth=1.2, label=tel.driver, alpha=0.8)
        
        ax.set_xlabel('Distance (m)', color=COLORS['text'])
        ax.set_ylabel('Throttle (%)', color=COLORS['text'])
        ax.set_ylim(-5, 105)
        ax.legend(loc='upper right', fontsize=8, facecolor=COLORS['panel_bg'],
                  edgecolor=COLORS['grid'], labelcolor=COLORS['text'])
    
    def plot_brake_comparison(self):
        """Plot overlaid brake traces."""
        ax = self.axes['brake']
        self._apply_style(ax, "Brake Pressure")
        
        for tel in self.telemetry_list:
            color = self.driver_colors[tel.driver]
            ax.plot(tel.distance, tel.brake, color=color,
                   linewidth=1.2, label=tel.driver, alpha=0.8)
        
        ax.set_xlabel('Distance (m)', color=COLORS['text'])
        ax.set_ylabel('Brake (%)', color=COLORS['text'])
        ax.set_ylim(-5, 105)
        ax.legend(loc='upper right', fontsize=8, facecolor=COLORS['panel_bg'],
                  edgecolor=COLORS['grid'], labelcolor=COLORS['text'])
    
    def plot_track_overlay(self):
        """Plot track positions for visual reference."""
        ax = self.axes['track']
        self._apply_style(ax, "Track Position Overlay")
        
        for tel in self.telemetry_list:
            if np.all(tel.x == 0) and np.all(tel.y == 0):
                continue
            
            color = self.driver_colors[tel.driver]
            ax.plot(tel.x, tel.y, color=color, linewidth=2,
                   label=tel.driver, alpha=0.7)
        
        ax.set_aspect('equal')
        ax.set_xticks([])
        ax.set_yticks([])
        
        if self.telemetry_list:
            ax.legend(loc='upper right', fontsize=9, facecolor=COLORS['panel_bg'],
                      edgecolor=COLORS['grid'], labelcolor=COLORS['text'])
    
    def plot_time_delta(self):
        """
        Plot cumulative time delta between first two drivers.
        
        Shows where time is gained/lost around the lap.
        """
        ax = self.axes['time_delta']
        self._apply_style(ax, "Cumulative Time Delta")
        
        if len(self.telemetry_list) < 2:
            ax.text(0.5, 0.5, "Need 2+ drivers for time delta",
                   transform=ax.transAxes, ha='center', va='center',
                   color=COLORS['text'])
            return
        
        tel1 = self.telemetry_list[0]
        tel2 = self.telemetry_list[1]
        
        time_delta, common_distance = calculate_time_delta(tel1, tel2)
        
        # Plot time delta
        ax.fill_between(common_distance, 0, time_delta,
                        where=time_delta >= 0, alpha=0.6,
                        color=self.driver_colors[tel1.driver])
        ax.fill_between(common_distance, 0, time_delta,
                        where=time_delta < 0, alpha=0.6,
                        color=self.driver_colors[tel2.driver])
        ax.plot(common_distance, time_delta, color='white', linewidth=1, alpha=0.8)
        
        ax.axhline(y=0, color=COLORS['text'], linewidth=0.5, alpha=0.5)
        
        # Final delta
        final_delta = time_delta[-1]
        winner = tel1.driver if final_delta > 0 else tel2.driver
        ax.text(0.98, 0.95, f"Δ {abs(final_delta):.3f}s ({winner} faster)",
               transform=ax.transAxes, ha='right', va='top',
               fontsize=10, color=COLORS['text'], fontweight='bold')
        
        ax.set_xlabel('Distance (m)', color=COLORS['text'])
        ax.set_ylabel('Time Δ (s)', color=COLORS['text'])
        ax.set_xlim(common_distance.min(), common_distance.max())
    
    def render(self):
        """Render all comparison plots."""
        self.plot_speed_comparison()
        self.plot_time_delta()
        self.plot_speed_delta()
        self.plot_throttle_comparison()
        self.plot_brake_comparison()
        self.plot_track_overlay()
        
        plt.tight_layout(rect=[0, 0, 1, 0.96])
    
    def show(self):
        """Display the comparison dashboard."""
        self.render()
        plt.show()


def calculate_time_delta(tel1: TelemetryData, tel2: TelemetryData) -> Tuple[np.ndarray, np.ndarray]:
    """
    Calculate cumulative time delta between two drivers.
    
    Args:
        tel1: First driver telemetry
        tel2: Second driver telemetry
        
    Returns:
        Time delta array (positive = tel1 ahead)
    """
    # Common distance basis
    min_dist = max(tel1.distance.min(), tel2.distance.min())
    max_dist = min(tel1.distance.max(), tel2.distance.max())
    common_distance = np.linspace(min_dist, max_dist, 1000)
    
    # Interpolate times
    time1 = np.interp(common_distance, tel1.distance, tel1.time)
    time2 = np.interp(common_distance, tel2.distance, tel2.time)
    
    # Calculate delta
    return time2 - time1, common_distance


def compare_drivers(session, driver_codes: List[str], drivers_info: List[dict]):
    """
    Create comparison visualization for multiple drivers.
    
    Args:
        session: Loaded FastF1 session
        driver_codes: List of driver codes to compare
        drivers_info: List of driver info dicts
    """
    telemetry_list = []
    
    for code in driver_codes:
        # Find driver info
        driver_info = {}
        for d in drivers_info:
            if d['code'] == code:
                driver_info = d
                break
        
        if not driver_info:
            driver_info = {'code': code, 'team': 'Unknown'}
        
        # Get lap and telemetry
        lap = get_driver_fastest_lap(session, code)
        if lap is None:
            print(f"[WARN] No lap found for {code}, skipping")
            continue
        
        tel = extract_telemetry(lap, driver_info)
        if tel:
            telemetry_list.append(tel)
            print(f"[OK] Loaded telemetry for {code}")
        else:
            print(f"[WARN] Failed to extract telemetry for {code}")
    
    if len(telemetry_list) < 2:
        print("[ERROR] Need at least 2 drivers for comparison")
        return None
    
    # Create comparison
    comparison = DriverComparison(telemetry_list)
    comparison.create_comparison()
    comparison.show()
    
    return comparison


if __name__ == "__main__":
    print("[INFO] Driver comparison module loaded")
    print("[INFO] Use compare_drivers(session, driver_codes, drivers_info) to compare")

