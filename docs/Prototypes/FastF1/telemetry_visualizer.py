#!/usr/bin/env python3
"""
telemetry_visualizer.py

Advanced telemetry visualization with multi-panel dashboard.
Creates comprehensive displays of F1 car telemetry data including
speed, throttle, brake, RPM, gear, and track position.
"""

import numpy as np
import matplotlib.pyplot as plt
from matplotlib.collections import LineCollection
from matplotlib.colors import LinearSegmentedColormap, Normalize
from matplotlib.gridspec import GridSpec
from typing import List, Optional, Tuple

from f1_fastf1_track_demo import (
    COLORS,
    TEAM_COLORS,
    TelemetryData,
    extract_telemetry,
    get_driver_fastest_lap,
)


def create_speed_colormap():
    """
    Create a custom colormap for speed visualization.
    
    Goes from deep blue (slow) through cyan and yellow to red (fast).
    """
    colors = ['#0d47a1', '#00bcd4', '#ffeb3b', '#ff5722', '#b71c1c']
    return LinearSegmentedColormap.from_list('speed_cmap', colors, N=256)


def create_racing_colormap():
    """
    Create a dramatic racing-style colormap.
    
    Deep purple to electric blue to hot pink.
    """
    colors = ['#1a0033', '#4a148c', '#00bcd4', '#e91e63', '#ff1744']
    return LinearSegmentedColormap.from_list('racing_cmap', colors, N=256)


class TelemetryDashboard:
    """
    Multi-panel dashboard for comprehensive telemetry visualization.
    
    Layout:
    - Large track map with speed-coloured trace (left)
    - Speed vs Distance (top right)
    - Throttle & Brake overlay (middle right)
    - RPM and Gear (bottom right)
    - Telemetry stats panel (bottom)
    """
    
    def __init__(self, telemetry: TelemetryData):
        self.telemetry = telemetry
        self.fig = None
        self.axes = {}
        
    def _apply_dark_theme(self, ax, title: str = ""):
        """Apply consistent dark theme styling to an axis."""
        ax.set_facecolor(COLORS['panel_bg'])
        ax.tick_params(colors=COLORS['text'], labelsize=8)
        ax.xaxis.label.set_color(COLORS['text'])
        ax.yaxis.label.set_color(COLORS['text'])
        
        if title:
            ax.set_title(title, color=COLORS['text'], fontsize=10, fontweight='bold', pad=8)
        
        for spine in ax.spines.values():
            spine.set_color(COLORS['grid'])
        
        ax.grid(True, alpha=0.2, color=COLORS['grid'], linestyle='--')
    
    def create_dashboard(self, figsize: Tuple[int, int] = (18, 10)):
        """
        Create the full dashboard layout with GridSpec.
        
        Args:
            figsize: Figure size in inches
        """
        self.fig = plt.figure(figsize=figsize, facecolor=COLORS['background'])
        
        # Create grid layout: 3 rows, 2 columns
        gs = GridSpec(3, 2, figure=self.fig, 
                      width_ratios=[1.2, 1],
                      height_ratios=[1, 1, 0.8],
                      hspace=0.3, wspace=0.25)
        
        # Track map takes left side (rows 0-1)
        self.axes['track'] = self.fig.add_subplot(gs[0:2, 0])
        
        # Speed trace (top right)
        self.axes['speed'] = self.fig.add_subplot(gs[0, 1])
        
        # Throttle/Brake (middle right)
        self.axes['throttle_brake'] = self.fig.add_subplot(gs[1, 1])
        
        # RPM and Gear (bottom, spans both columns)
        self.axes['rpm_gear'] = self.fig.add_subplot(gs[2, :])
        
        # Main title
        driver = self.telemetry.driver
        team = self.telemetry.team
        lap_num = self.telemetry.lap_number
        lap_time = self.telemetry.lap_time or "N/A"
        
        team_color = TEAM_COLORS.get(team, COLORS['accent'])
        
        title = f"{driver} - Lap {lap_num} ({lap_time}) | {team}"
        self.fig.suptitle(title, fontsize=16, color=team_color, fontweight='bold', y=0.98)
        
        return self.fig
    
    def plot_track_map(self):
        """
        Plot the track map with speed-coloured trace.
        
        Uses LineCollection for efficient gradient coloring along the path.
        """
        ax = self.axes['track']
        self._apply_dark_theme(ax, "Track Position - Speed Heatmap")
        
        x = self.telemetry.x
        y = self.telemetry.y
        speed = self.telemetry.speed
        
        # Check if we have valid position data
        if np.all(x == 0) and np.all(y == 0):
            ax.text(0.5, 0.5, "Position data unavailable", 
                   transform=ax.transAxes, ha='center', va='center',
                   color=COLORS['text'], fontsize=14)
            return
        
        # Create line segments for gradient coloring
        points = np.array([x, y]).T.reshape(-1, 1, 2)
        segments = np.concatenate([points[:-1], points[1:]], axis=1)
        
        # Normalize speed for colormap
        norm = Normalize(vmin=speed.min(), vmax=speed.max())
        cmap = create_speed_colormap()
        
        # Create LineCollection
        lc = LineCollection(segments, cmap=cmap, norm=norm, linewidth=3, alpha=0.9)
        lc.set_array(speed[:-1])
        ax.add_collection(lc)
        
        # Add start/finish marker
        ax.plot(x[0], y[0], 'o', color=COLORS['throttle'], markersize=12, 
                label='Start/Finish', zorder=5)
        ax.plot(x[0], y[0], 'o', color='white', markersize=6, zorder=6)
        
        # Set equal aspect and limits
        ax.set_aspect('equal')
        margin = 50
        ax.set_xlim(x.min() - margin, x.max() + margin)
        ax.set_ylim(y.min() - margin, y.max() + margin)
        
        ax.set_xlabel('X Position (m)')
        ax.set_ylabel('Y Position (m)')
        
        # Add colorbar
        cbar = self.fig.colorbar(lc, ax=ax, orientation='horizontal', 
                                  fraction=0.05, pad=0.12, aspect=40)
        cbar.set_label('Speed (km/h)', color=COLORS['text'])
        cbar.ax.tick_params(colors=COLORS['text'])
        
        # Add speed annotations at key points
        max_speed_idx = np.argmax(speed)
        min_speed_idx = np.argmin(speed)
        
        ax.annotate(f'MAX: {speed[max_speed_idx]:.0f} km/h',
                   xy=(x[max_speed_idx], y[max_speed_idx]),
                   xytext=(10, 10), textcoords='offset points',
                   color=COLORS['accent'], fontsize=8, fontweight='bold',
                   arrowprops=dict(arrowstyle='->', color=COLORS['accent'], lw=1))
        
        ax.annotate(f'MIN: {speed[min_speed_idx]:.0f} km/h',
                   xy=(x[min_speed_idx], y[min_speed_idx]),
                   xytext=(10, -15), textcoords='offset points',
                   color=COLORS['secondary'], fontsize=8, fontweight='bold',
                   arrowprops=dict(arrowstyle='->', color=COLORS['secondary'], lw=1))
    
    def plot_speed_trace(self):
        """Plot speed vs distance with gradient fill."""
        ax = self.axes['speed']
        self._apply_dark_theme(ax, "Speed Trace")
        
        distance = self.telemetry.distance
        speed = self.telemetry.speed
        
        # Main line
        ax.plot(distance, speed, color=COLORS['speed'], linewidth=1.5, alpha=0.9)
        
        # Gradient fill under the curve
        ax.fill_between(distance, 0, speed, alpha=0.3, color=COLORS['speed'])
        
        # Add horizontal lines for reference
        ax.axhline(y=speed.max(), color=COLORS['accent'], linestyle='--', 
                   alpha=0.5, linewidth=1, label=f'Max: {speed.max():.0f} km/h')
        ax.axhline(y=speed.mean(), color=COLORS['secondary'], linestyle=':', 
                   alpha=0.5, linewidth=1, label=f'Avg: {speed.mean():.0f} km/h')
        
        ax.set_xlabel('Distance (m)')
        ax.set_ylabel('Speed (km/h)')
        ax.set_xlim(distance.min(), distance.max())
        ax.set_ylim(0, speed.max() * 1.1)
        
        ax.legend(loc='upper right', fontsize=8, facecolor=COLORS['panel_bg'],
                  edgecolor=COLORS['grid'], labelcolor=COLORS['text'])
    
    def plot_throttle_brake(self):
        """Plot throttle and brake traces overlaid."""
        ax = self.axes['throttle_brake']
        self._apply_dark_theme(ax, "Throttle & Brake")
        
        distance = self.telemetry.distance
        throttle = self.telemetry.throttle
        brake = self.telemetry.brake
        
        # Throttle (green)
        ax.fill_between(distance, 0, throttle, alpha=0.6, color=COLORS['throttle'], 
                        label='Throttle')
        ax.plot(distance, throttle, color=COLORS['throttle'], linewidth=0.8)
        
        # Brake (red, inverted for visibility)
        ax.fill_between(distance, 0, -brake, alpha=0.6, color=COLORS['brake'],
                        label='Brake')
        ax.plot(distance, -brake, color=COLORS['brake'], linewidth=0.8)
        
        ax.set_xlabel('Distance (m)')
        ax.set_ylabel('Throttle / Brake (%)')
        ax.set_xlim(distance.min(), distance.max())
        ax.set_ylim(-110, 110)
        
        # Zero line
        ax.axhline(y=0, color=COLORS['text'], linewidth=0.5, alpha=0.5)
        
        ax.legend(loc='upper right', fontsize=8, facecolor=COLORS['panel_bg'],
                  edgecolor=COLORS['grid'], labelcolor=COLORS['text'])
    
    def plot_rpm_gear(self):
        """Plot RPM and gear on a dual-axis chart."""
        ax = self.axes['rpm_gear']
        self._apply_dark_theme(ax, "RPM & Gear Selection")
        
        distance = self.telemetry.distance
        rpm = self.telemetry.rpm
        gear = self.telemetry.gear
        
        # RPM on primary axis
        color_rpm = COLORS['rpm']
        ax.set_xlabel('Distance (m)')
        ax.set_ylabel('RPM', color=color_rpm)
        ax.plot(distance, rpm, color=color_rpm, linewidth=1, alpha=0.8, label='RPM')
        ax.tick_params(axis='y', labelcolor=color_rpm)
        ax.set_xlim(distance.min(), distance.max())
        
        # RPM redline indicator
        if rpm.max() > 10000:
            ax.axhline(y=11500, color=COLORS['accent'], linestyle='--', 
                       alpha=0.5, linewidth=1, label='Redline ~11.5k')
        
        # Gear on secondary axis
        ax2 = ax.twinx()
        color_gear = COLORS['gear']
        ax2.set_ylabel('Gear', color=color_gear)
        ax2.step(distance, gear, color=color_gear, linewidth=2, alpha=0.9, 
                 where='mid', label='Gear')
        ax2.tick_params(axis='y', labelcolor=color_gear)
        ax2.set_ylim(0, 9)
        ax2.set_yticks(range(0, 9))
        
        # Apply dark theme to secondary axis
        for spine in ax2.spines.values():
            spine.set_color(COLORS['grid'])
    
    def render(self):
        """Render all dashboard components."""
        self.plot_track_map()
        self.plot_speed_trace()
        self.plot_throttle_brake()
        self.plot_rpm_gear()
        
        plt.tight_layout(rect=[0, 0, 1, 0.96])
    
    def show(self):
        """Display the dashboard."""
        self.render()
        plt.show()
    
    def save(self, filename: str, dpi: int = 150):
        """Save the dashboard to a file."""
        self.render()
        self.fig.savefig(filename, dpi=dpi, facecolor=COLORS['background'],
                         edgecolor='none', bbox_inches='tight')
        print(f"[INFO] Dashboard saved to {filename}")


def visualize_lap(session, driver_code: str, drivers_info: List[dict]):
    """
    Create and display telemetry dashboard for a driver's fastest lap.
    
    Args:
        session: Loaded FastF1 session
        driver_code: 3-letter driver code
        drivers_info: List of driver info dicts
    """
    # Find driver info
    driver_info = {}
    for d in drivers_info:
        if d['code'] == driver_code:
            driver_info = d
            break
    
    if not driver_info:
        driver_info = {'code': driver_code, 'team': 'Unknown', 'name': driver_code}
    
    # Get fastest lap
    lap = get_driver_fastest_lap(session, driver_code)
    if lap is None:
        print(f"[ERROR] No lap found for {driver_code}")
        return None
    
    # Extract telemetry
    telemetry = extract_telemetry(lap, driver_info)
    if telemetry is None:
        print(f"[ERROR] Failed to extract telemetry for {driver_code}")
        return None
    
    # Create dashboard
    dashboard = TelemetryDashboard(telemetry)
    dashboard.create_dashboard()
    dashboard.show()
    
    return dashboard


if __name__ == "__main__":
    print("[INFO] Telemetry visualizer module loaded")
    print("[INFO] Use visualize_lap(session, driver_code, drivers_info) to create dashboard")

