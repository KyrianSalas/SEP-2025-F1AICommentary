#!/usr/bin/env python3
"""
corner_analysis.py

Identify and analyze corners from telemetry data.
Detects braking zones, apex points, and corner exit speeds.
"""

import numpy as np
import matplotlib.pyplot as plt
from matplotlib.gridspec import GridSpec
from typing import List, Optional, Tuple
from dataclasses import dataclass

from f1_fastf1_track_demo import (
    COLORS,
    TEAM_COLORS,
    TelemetryData,
    extract_telemetry,
    get_driver_fastest_lap,
)


@dataclass
class Corner:
    """Data structure for a detected corner."""
    index: int
    brake_start_idx: int
    apex_idx: int
    exit_idx: int
    entry_speed: float
    apex_speed: float
    exit_speed: float
    brake_distance: float
    max_brake_pressure: float
    gear_at_apex: int


def detect_corners(telemetry: TelemetryData, 
                   min_speed_drop: float = 30.0,
                   min_brake_pressure: float = 20.0) -> List[Corner]:
    """
    Detect corners from telemetry data based on speed and braking patterns.
    
    Args:
        telemetry: TelemetryData object
        min_speed_drop: Minimum speed reduction to classify as corner
        min_brake_pressure: Minimum brake pressure to detect braking
        
    Returns:
        List of Corner objects
    """
    speed = telemetry.speed
    brake = telemetry.brake
    distance = telemetry.distance
    gear = telemetry.gear
    
    corners = []
    in_corner = False
    corner_idx = 0
    
    i = 0
    while i < len(speed) - 10:
        # Look for braking zone entry
        if not in_corner and brake[i] > min_brake_pressure:
            # Find start of braking
            brake_start = i
            while brake_start > 0 and brake[brake_start - 1] > min_brake_pressure * 0.5:
                brake_start -= 1
            
            entry_speed = speed[brake_start]
            
            # Find apex (minimum speed point)
            search_end = min(i + 200, len(speed))
            apex_idx = brake_start + np.argmin(speed[brake_start:search_end])
            apex_speed = speed[apex_idx]
            
            # Check if this is a significant corner
            speed_drop = entry_speed - apex_speed
            if speed_drop >= min_speed_drop:
                # Find corner exit (speed recovery)
                exit_idx = apex_idx
                target_exit_speed = apex_speed + speed_drop * 0.7
                while exit_idx < len(speed) - 1 and speed[exit_idx] < target_exit_speed:
                    exit_idx += 1
                
                corner = Corner(
                    index=corner_idx,
                    brake_start_idx=brake_start,
                    apex_idx=apex_idx,
                    exit_idx=exit_idx,
                    entry_speed=entry_speed,
                    apex_speed=apex_speed,
                    exit_speed=speed[exit_idx],
                    brake_distance=distance[apex_idx] - distance[brake_start],
                    max_brake_pressure=float(np.max(brake[brake_start:apex_idx])),
                    gear_at_apex=int(gear[apex_idx]),
                )
                corners.append(corner)
                corner_idx += 1
                
                # Move past this corner
                i = exit_idx
                in_corner = False
            else:
                i += 10
        else:
            i += 1
    
    return corners


class CornerAnalyzer:
    """
    Visualize corner-by-corner analysis.
    
    Features:
    - Corner detection and labeling on track
    - Speed profiles through each corner
    - Braking zone comparison
    """
    
    def __init__(self, telemetry: TelemetryData):
        self.telemetry = telemetry
        self.corners = detect_corners(telemetry)
        self.fig = None
        self.axes = {}
        
        team_color = TEAM_COLORS.get(telemetry.team, COLORS['accent'])
        self.driver_color = team_color
        
        print(f"[INFO] Detected {len(self.corners)} corners")
    
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
        """Create the corner analysis figure."""
        self.fig = plt.figure(figsize=figsize, facecolor=COLORS['background'])
        
        gs = GridSpec(2, 2, figure=self.fig, hspace=0.3, wspace=0.25)
        
        # Track with corners labeled
        self.axes['track'] = self.fig.add_subplot(gs[0, 0])
        
        # Corner speeds bar chart
        self.axes['speeds'] = self.fig.add_subplot(gs[0, 1])
        
        # Braking distances
        self.axes['braking'] = self.fig.add_subplot(gs[1, 0])
        
        # Gear at apex
        self.axes['gears'] = self.fig.add_subplot(gs[1, 1])
        
        # Title
        driver = self.telemetry.driver
        lap_time = self.telemetry.lap_time or "N/A"
        title = f"{driver} - Corner Analysis | {len(self.corners)} Corners Detected"
        self.fig.suptitle(title, fontsize=16, color=self.driver_color,
                         fontweight='bold', y=0.98)
        
        return self.fig
    
    def plot_track_corners(self):
        """Plot track with corners labeled."""
        ax = self.axes['track']
        self._apply_style(ax, "Track Layout with Corners")
        
        x = self.telemetry.x
        y = self.telemetry.y
        
        if np.all(x == 0) and np.all(y == 0):
            ax.text(0.5, 0.5, "Position data unavailable",
                   transform=ax.transAxes, ha='center', va='center',
                   color=COLORS['text'], fontsize=14)
            return
        
        # Draw track
        ax.plot(x, y, color='#3a3a5a', linewidth=8, solid_capstyle='round')
        ax.plot(x, y, color=self.driver_color, linewidth=2, alpha=0.7)
        
        # Mark corners
        for corner in self.corners:
            apex_x = x[corner.apex_idx]
            apex_y = y[corner.apex_idx]
            
            # Apex marker
            ax.plot(apex_x, apex_y, 'o', color=COLORS['brake'], 
                   markersize=10, markeredgecolor='white', markeredgewidth=1)
            
            # Corner number
            ax.annotate(f"T{corner.index + 1}", (apex_x, apex_y),
                       xytext=(8, 8), textcoords='offset points',
                       color='white', fontsize=8, fontweight='bold',
                       bbox=dict(boxstyle='round,pad=0.2', 
                                facecolor=COLORS['brake'], alpha=0.8))
            
            # Braking zone (entry to apex)
            brake_x = x[corner.brake_start_idx:corner.apex_idx]
            brake_y = y[corner.brake_start_idx:corner.apex_idx]
            ax.plot(brake_x, brake_y, color=COLORS['brake'], linewidth=5, alpha=0.6)
        
        ax.set_aspect('equal')
        ax.set_xticks([])
        ax.set_yticks([])
    
    def plot_corner_speeds(self):
        """Bar chart of speeds at each corner."""
        ax = self.axes['speeds']
        self._apply_style(ax, "Corner Speeds")
        
        if not self.corners:
            ax.text(0.5, 0.5, "No corners detected",
                   transform=ax.transAxes, ha='center', va='center',
                   color=COLORS['text'])
            return
        
        corners = list(range(1, len(self.corners) + 1))
        entry_speeds = [c.entry_speed for c in self.corners]
        apex_speeds = [c.apex_speed for c in self.corners]
        exit_speeds = [c.exit_speed for c in self.corners]
        
        x = np.array(corners)
        width = 0.25
        
        ax.bar(x - width, entry_speeds, width, color=COLORS['secondary'],
              alpha=0.8, label='Entry')
        ax.bar(x, apex_speeds, width, color=COLORS['brake'],
              alpha=0.8, label='Apex')
        ax.bar(x + width, exit_speeds, width, color=COLORS['throttle'],
              alpha=0.8, label='Exit')
        
        ax.set_xlabel('Corner', color=COLORS['text'])
        ax.set_ylabel('Speed (km/h)', color=COLORS['text'])
        ax.set_xticks(corners)
        ax.set_xticklabels([f"T{c}" for c in corners])
        ax.legend(fontsize=8, facecolor=COLORS['panel_bg'],
                  edgecolor=COLORS['grid'], labelcolor=COLORS['text'])
    
    def plot_braking_distances(self):
        """Bar chart of braking distances."""
        ax = self.axes['braking']
        self._apply_style(ax, "Braking Distances")
        
        if not self.corners:
            return
        
        corners = [f"T{c.index + 1}" for c in self.corners]
        distances = [c.brake_distance for c in self.corners]
        pressures = [c.max_brake_pressure for c in self.corners]
        
        # Normalize pressures for color mapping
        if max(pressures) > 0:
            normalized = [p / max(pressures) for p in pressures]
            colors = [plt.cm.Reds(0.3 + 0.7 * n) for n in normalized]
        else:
            colors = [COLORS['brake']] * len(corners)
        
        ax.barh(corners, distances, color=colors, edgecolor=COLORS['grid'])
        ax.set_xlabel('Braking Distance (m)', color=COLORS['text'])
        ax.set_ylabel('Corner', color=COLORS['text'])
        
        # Add pressure annotations
        for i, (d, p) in enumerate(zip(distances, pressures)):
            ax.text(d + 2, i, f"{p:.0f}%", va='center', fontsize=8,
                   color=COLORS['text'])
    
    def plot_apex_gears(self):
        """Bar chart of gear at apex for each corner."""
        ax = self.axes['gears']
        self._apply_style(ax, "Gear at Apex")
        
        if not self.corners:
            return
        
        corners = [f"T{c.index + 1}" for c in self.corners]
        gears = [c.gear_at_apex for c in self.corners]
        
        colors = plt.cm.viridis(np.array(gears) / 8)
        
        ax.bar(corners, gears, color=colors, edgecolor=COLORS['grid'])
        ax.set_xlabel('Corner', color=COLORS['text'])
        ax.set_ylabel('Gear', color=COLORS['text'])
        ax.set_ylim(0, 9)
        ax.set_yticks(range(0, 9))
        
        # Average gear line
        avg_gear = np.mean(gears)
        ax.axhline(y=avg_gear, color=COLORS['accent'], linestyle='--',
                   linewidth=1.5, label=f'Avg: {avg_gear:.1f}')
        ax.legend(fontsize=8, facecolor=COLORS['panel_bg'],
                  edgecolor=COLORS['grid'], labelcolor=COLORS['text'])
    
    def render(self):
        """Render all analysis plots."""
        self.plot_track_corners()
        self.plot_corner_speeds()
        self.plot_braking_distances()
        self.plot_apex_gears()
        
        plt.tight_layout(rect=[0, 0, 1, 0.96])
    
    def show(self):
        """Display the analysis."""
        self.render()
        plt.show()


def analyze_corners(session, driver_code: str, drivers_info: List[dict]):
    """
    Run corner analysis for a driver's fastest lap.
    
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
    
    analyzer = CornerAnalyzer(telemetry)
    analyzer.create_analysis()
    analyzer.show()
    
    return analyzer


if __name__ == "__main__":
    print("[INFO] Corner analysis module loaded")
    print("[INFO] Use analyze_corners(session, driver_code, drivers_info) for analysis")

