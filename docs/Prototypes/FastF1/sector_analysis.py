#!/usr/bin/env python3
"""
sector_analysis.py

Sector-by-sector lap analysis with mini-sector breakdowns.
Analyzes performance at different parts of the track.
"""

import numpy as np
import matplotlib.pyplot as plt
from matplotlib.gridspec import GridSpec
from matplotlib.patches import Rectangle
from typing import List, Optional, Tuple

from f1_fastf1_track_demo import (
    COLORS,
    TEAM_COLORS,
    TelemetryData,
    extract_telemetry,
    get_driver_fastest_lap,
)


def calculate_mini_sectors(telemetry: TelemetryData, num_sectors: int = 25) -> List[dict]:
    """
    Divide the lap into mini-sectors and calculate statistics for each.
    
    Args:
        telemetry: TelemetryData object
        num_sectors: Number of mini-sectors to divide the lap into
        
    Returns:
        List of dicts with sector statistics
    """
    distance = telemetry.distance
    speed = telemetry.speed
    throttle = telemetry.throttle
    brake = telemetry.brake
    
    total_distance = distance.max() - distance.min()
    sector_length = total_distance / num_sectors
    
    sectors = []
    
    for i in range(num_sectors):
        start_dist = distance.min() + i * sector_length
        end_dist = start_dist + sector_length
        
        # Find indices for this sector
        mask = (distance >= start_dist) & (distance < end_dist)
        
        if not np.any(mask):
            continue
        
        sector_speed = speed[mask]
        sector_throttle = throttle[mask]
        sector_brake = brake[mask]
        sector_time = telemetry.time[mask]
        
        # Calculate sector time
        if len(sector_time) > 1:
            sector_duration = sector_time[-1] - sector_time[0]
        else:
            sector_duration = 0
        
        sectors.append({
            'index': i,
            'start_distance': start_dist,
            'end_distance': end_dist,
            'avg_speed': np.mean(sector_speed),
            'max_speed': np.max(sector_speed),
            'min_speed': np.min(sector_speed),
            'avg_throttle': np.mean(sector_throttle),
            'avg_brake': np.mean(sector_brake),
            'duration': sector_duration,
            'x_start': telemetry.x[mask][0] if np.any(mask) else 0,
            'y_start': telemetry.y[mask][0] if np.any(mask) else 0,
        })
    
    return sectors


class SectorAnalyzer:
    """
    Visualize sector-by-sector performance analysis.
    
    Features:
    - Mini-sector speed breakdown
    - Throttle/brake zone identification
    - Time loss analysis per sector
    """
    
    def __init__(self, telemetry: TelemetryData, num_sectors: int = 25):
        self.telemetry = telemetry
        self.num_sectors = num_sectors
        self.sectors = calculate_mini_sectors(telemetry, num_sectors)
        self.fig = None
        self.axes = {}
        
        team_color = TEAM_COLORS.get(telemetry.team, COLORS['accent'])
        self.driver_color = team_color
    
    def _apply_style(self, ax, title: str = ""):
        """Apply dark theme styling."""
        ax.set_facecolor(COLORS['panel_bg'])
        ax.tick_params(colors=COLORS['text'], labelsize=8)
        
        if title:
            ax.set_title(title, color=COLORS['text'], fontsize=11, 
                        fontweight='bold', pad=8)
        
        for spine in ax.spines.values():
            spine.set_color(COLORS['grid'])
        
        ax.grid(True, alpha=0.15, color=COLORS['grid'])
    
    def create_analysis(self, figsize: Tuple[int, int] = (16, 10)):
        """Create the sector analysis figure."""
        self.fig = plt.figure(figsize=figsize, facecolor=COLORS['background'])
        
        gs = GridSpec(3, 2, figure=self.fig, 
                      hspace=0.35, wspace=0.25,
                      height_ratios=[1.2, 1, 1])
        
        # Track with sectors (top, full width)
        self.axes['track'] = self.fig.add_subplot(gs[0, :])
        
        # Average speed by sector
        self.axes['speed_sectors'] = self.fig.add_subplot(gs[1, 0])
        
        # Sector durations
        self.axes['duration'] = self.fig.add_subplot(gs[1, 1])
        
        # Throttle vs brake zones
        self.axes['zones'] = self.fig.add_subplot(gs[2, :])
        
        # Title
        driver = self.telemetry.driver
        lap_time = self.telemetry.lap_time or "N/A"
        title = f"{driver} - Sector Analysis | Lap Time: {lap_time}"
        self.fig.suptitle(title, fontsize=16, color=self.driver_color,
                         fontweight='bold', y=0.98)
        
        return self.fig
    
    def plot_track_sectors(self):
        """Plot track with colour-coded speed sectors."""
        ax = self.axes['track']
        self._apply_style(ax, "Track Speed Map by Mini-Sector")
        
        x = self.telemetry.x
        y = self.telemetry.y
        
        if np.all(x == 0) and np.all(y == 0):
            ax.text(0.5, 0.5, "Position data unavailable",
                   transform=ax.transAxes, ha='center', va='center',
                   color=COLORS['text'], fontsize=14)
            return
        
        # Get speed range for coloring
        speeds = [s['avg_speed'] for s in self.sectors]
        min_speed = min(speeds)
        max_speed = max(speeds)
        
        # Plot each sector with speed-based color
        from matplotlib.colors import Normalize
        from telemetry_visualizer import create_speed_colormap
        
        cmap = create_speed_colormap()
        norm = Normalize(vmin=min_speed, vmax=max_speed)
        
        for i, sector in enumerate(self.sectors):
            start = sector['start_distance']
            end = sector['end_distance']
            
            mask = ((self.telemetry.distance >= start) & 
                   (self.telemetry.distance < end))
            
            if np.any(mask):
                color = cmap(norm(sector['avg_speed']))
                ax.plot(x[mask], y[mask], color=color, linewidth=4, 
                       solid_capstyle='round')
        
        ax.set_aspect('equal')
        ax.set_xticks([])
        ax.set_yticks([])
        
        # Colorbar
        sm = plt.cm.ScalarMappable(cmap=cmap, norm=norm)
        cbar = self.fig.colorbar(sm, ax=ax, orientation='horizontal',
                                  fraction=0.03, pad=0.05, aspect=50)
        cbar.set_label('Avg Speed (km/h)', color=COLORS['text'])
        cbar.ax.tick_params(colors=COLORS['text'])
    
    def plot_speed_by_sector(self):
        """Bar chart of average speed per sector."""
        ax = self.axes['speed_sectors']
        self._apply_style(ax, "Average Speed by Sector")
        
        indices = [s['index'] for s in self.sectors]
        speeds = [s['avg_speed'] for s in self.sectors]
        
        # Color bars by speed
        from matplotlib.colors import Normalize
        from telemetry_visualizer import create_speed_colormap
        
        cmap = create_speed_colormap()
        norm = Normalize(vmin=min(speeds), vmax=max(speeds))
        colors = [cmap(norm(s)) for s in speeds]
        
        bars = ax.bar(indices, speeds, color=colors, edgecolor=COLORS['grid'],
                     linewidth=0.5)
        
        ax.set_xlabel('Sector', color=COLORS['text'])
        ax.set_ylabel('Speed (km/h)', color=COLORS['text'])
        
        # Add average line
        avg_speed = np.mean(speeds)
        ax.axhline(y=avg_speed, color=COLORS['secondary'], linestyle='--',
                   linewidth=1.5, label=f'Avg: {avg_speed:.1f} km/h')
        ax.legend(fontsize=8, facecolor=COLORS['panel_bg'],
                  edgecolor=COLORS['grid'], labelcolor=COLORS['text'])
    
    def plot_sector_durations(self):
        """Plot time spent in each sector."""
        ax = self.axes['duration']
        self._apply_style(ax, "Sector Duration")
        
        indices = [s['index'] for s in self.sectors]
        durations = [s['duration'] * 1000 for s in self.sectors]  # Convert to ms
        
        ax.bar(indices, durations, color=self.driver_color, alpha=0.8,
              edgecolor=COLORS['grid'], linewidth=0.5)
        
        ax.set_xlabel('Sector', color=COLORS['text'])
        ax.set_ylabel('Duration (ms)', color=COLORS['text'])
        
        # Highlight slowest sectors
        max_duration = max(durations)
        for i, (idx, dur) in enumerate(zip(indices, durations)):
            if dur >= max_duration * 0.95:  # Top 5% slowest
                ax.bar([idx], [dur], color=COLORS['brake'], alpha=0.8,
                      edgecolor=COLORS['grid'])
    
    def plot_throttle_brake_zones(self):
        """Visualize throttle vs brake application across the lap."""
        ax = self.axes['zones']
        self._apply_style(ax, "Throttle & Brake Zones by Sector")
        
        indices = [s['index'] for s in self.sectors]
        throttle = [s['avg_throttle'] for s in self.sectors]
        brake = [s['avg_brake'] for s in self.sectors]
        
        width = 0.35
        x = np.array(indices)
        
        ax.bar(x - width/2, throttle, width, color=COLORS['throttle'],
              alpha=0.8, label='Throttle %')
        ax.bar(x + width/2, brake, width, color=COLORS['brake'],
              alpha=0.8, label='Brake %')
        
        ax.set_xlabel('Sector', color=COLORS['text'])
        ax.set_ylabel('Average %', color=COLORS['text'])
        ax.set_ylim(0, 105)
        
        ax.legend(fontsize=9, facecolor=COLORS['panel_bg'],
                  edgecolor=COLORS['grid'], labelcolor=COLORS['text'],
                  loc='upper right')
        
        # Identify heavy braking zones
        heavy_brake_threshold = 30
        for i, (idx, b) in enumerate(zip(indices, brake)):
            if b > heavy_brake_threshold:
                ax.axvline(x=idx, color=COLORS['accent'], alpha=0.3,
                          linestyle='-', linewidth=8)
    
    def render(self):
        """Render all analysis plots."""
        self.plot_track_sectors()
        self.plot_speed_by_sector()
        self.plot_sector_durations()
        self.plot_throttle_brake_zones()
        
        plt.tight_layout(rect=[0, 0, 1, 0.96])
    
    def show(self):
        """Display the analysis."""
        self.render()
        plt.show()


def analyze_sectors(session, driver_code: str, drivers_info: List[dict], 
                    num_sectors: int = 25):
    """
    Run sector analysis for a driver's fastest lap.
    
    Args:
        session: Loaded FastF1 session
        driver_code: 3-letter driver code
        drivers_info: List of driver info dicts
        num_sectors: Number of mini-sectors
    """
    # Find driver info
    driver_info = {}
    for d in drivers_info:
        if d['code'] == driver_code:
            driver_info = d
            break
    
    if not driver_info:
        driver_info = {'code': driver_code, 'team': 'Unknown'}
    
    # Get lap
    lap = get_driver_fastest_lap(session, driver_code)
    if lap is None:
        print(f"[ERROR] No lap found for {driver_code}")
        return None
    
    # Extract telemetry
    telemetry = extract_telemetry(lap, driver_info)
    if telemetry is None:
        print(f"[ERROR] Failed to extract telemetry for {driver_code}")
        return None
    
    # Create analyzer
    analyzer = SectorAnalyzer(telemetry, num_sectors)
    analyzer.create_analysis()
    analyzer.show()
    
    return analyzer


if __name__ == "__main__":
    print("[INFO] Sector analysis module loaded")
    print("[INFO] Use analyze_sectors(session, driver_code, drivers_info) for analysis")

