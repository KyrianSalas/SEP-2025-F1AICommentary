#!/usr/bin/env python3
"""
track_animation.py

Animated track visualization showing car position and live telemetry.
Features smooth animation with speed-based colouring and live telemetry readouts.
"""

import numpy as np
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
from matplotlib.collections import LineCollection
from matplotlib.colors import Normalize
from matplotlib.patches import Circle, FancyBboxPatch
from typing import List, Optional, Tuple

from f1_fastf1_track_demo import (
    COLORS,
    TEAM_COLORS,
    TelemetryData,
    extract_telemetry,
    get_driver_fastest_lap,
)
from telemetry_visualizer import create_speed_colormap


class TrackAnimator:
    """
    Animated visualization of car movement around the track with live telemetry.
    
    Features:
    - Speed-coloured track trace
    - Animated car position marker
    - Live telemetry readouts (speed, gear, throttle, brake)
    - Trail effect showing recent positions
    - Keyboard controls for pause/play and speed
    """
    
    def __init__(self, telemetry: TelemetryData, team_color: str = None):
        self.telemetry = telemetry
        self.team_color = team_color or TEAM_COLORS.get(
            telemetry.team, COLORS['accent']
        )
        
        self.fig = None
        self.ax_track = None
        self.ax_speed = None
        self.ax_telemetry = None
        
        self.animation = None
        self.is_paused = False
        self.current_frame = 0
        self.interval_ms = 16  # ~60 FPS
        self.base_interval = 16
        
        # Animation artists
        self.car_marker = None
        self.trail_line = None
        self.speed_line = None
        self.speed_marker = None
        self.telemetry_texts = {}
        
        # Trail settings
        self.trail_length = 50
    
    def create_figure(self, figsize: Tuple[int, int] = (16, 9)):
        """Create the animated visualization figure."""
        self.fig = plt.figure(figsize=figsize, facecolor=COLORS['background'])
        
        # Layout: Track on left (large), telemetry panels on right
        self.ax_track = self.fig.add_axes([0.02, 0.1, 0.65, 0.85])
        self.ax_speed = self.fig.add_axes([0.70, 0.55, 0.28, 0.35])
        self.ax_telemetry = self.fig.add_axes([0.70, 0.1, 0.28, 0.40])
        
        self._setup_track_axes()
        self._setup_speed_axes()
        self._setup_telemetry_panel()
        self._setup_title()
        
        return self.fig
    
    def _apply_style(self, ax, title: str = ""):
        """Apply dark theme to axes."""
        ax.set_facecolor(COLORS['panel_bg'])
        ax.tick_params(colors=COLORS['text'], labelsize=9)
        
        for label in ax.get_xticklabels() + ax.get_yticklabels():
            label.set_color(COLORS['text'])
        
        if title:
            ax.set_title(title, color=COLORS['text'], fontsize=11, 
                        fontweight='bold', pad=10)
        
        for spine in ax.spines.values():
            spine.set_color(COLORS['grid'])
        
        ax.grid(True, alpha=0.15, color=COLORS['grid'], linestyle='-')
    
    def _setup_title(self):
        """Setup main title with driver and lap info."""
        driver = self.telemetry.driver
        lap_num = self.telemetry.lap_number
        lap_time = self.telemetry.lap_time or "N/A"
        team = self.telemetry.team
        
        title = f"{driver} | Lap {lap_num} | {lap_time}"
        subtitle = team
        
        self.fig.suptitle(title, fontsize=18, color=self.team_color, 
                         fontweight='bold', y=0.98)
        self.fig.text(0.5, 0.93, subtitle, fontsize=12, color=COLORS['text'],
                     ha='center', alpha=0.8)
    
    def _setup_track_axes(self):
        """Setup the track map axes with the circuit outline."""
        ax = self.ax_track
        self._apply_style(ax, "")
        
        x = self.telemetry.x
        y = self.telemetry.y
        speed = self.telemetry.speed
        
        # Check for valid position data
        if np.all(x == 0) and np.all(y == 0):
            ax.text(0.5, 0.5, "Position data unavailable",
                   transform=ax.transAxes, ha='center', va='center',
                   color=COLORS['text'], fontsize=16)
            return
        
        # Draw base track in dark grey
        ax.plot(x, y, color='#2a2a3e', linewidth=12, solid_capstyle='round', 
                zorder=1, alpha=0.6)
        
        # Draw speed-coloured overlay
        points = np.array([x, y]).T.reshape(-1, 1, 2)
        segments = np.concatenate([points[:-1], points[1:]], axis=1)
        
        norm = Normalize(vmin=speed.min(), vmax=speed.max())
        cmap = create_speed_colormap()
        
        lc = LineCollection(segments, cmap=cmap, norm=norm, linewidth=4, 
                           alpha=0.8, zorder=2)
        lc.set_array(speed[:-1])
        ax.add_collection(lc)
        
        # Start/finish line
        ax.plot(x[0], y[0], 's', color='white', markersize=10, zorder=3)
        ax.annotate('S/F', (x[0], y[0]), xytext=(15, 15), 
                   textcoords='offset points', color='white', fontsize=10,
                   fontweight='bold')
        
        # Initialise trail segments for gradient fade effect
        self.trail_segments = []
        num_trail_segments = 10
        for i in range(num_trail_segments):
            alpha = 0.1 + (i / num_trail_segments) * 0.7
            width = 1 + (i / num_trail_segments) * 2
            line, = ax.plot([], [], color=self.team_color,
                           linewidth=width, alpha=alpha, zorder=4)
            self.trail_segments.append(line)
        
        # Keep main trail for compatibility
        self.trail_line, = ax.plot([], [], color=self.team_color, 
                                   linewidth=3, alpha=0.8, zorder=4)
        
        # Car marker (will be animated)
        self.car_marker, = ax.plot([], [], 'o', color=self.team_color,
                                   markersize=16, markeredgecolor='white',
                                   markeredgewidth=2, zorder=5)
        
        # Set equal aspect
        ax.set_aspect('equal')
        margin = 100
        ax.set_xlim(x.min() - margin, x.max() + margin)
        ax.set_ylim(y.min() - margin, y.max() + margin)
        
        # Remove axis labels for cleaner look
        ax.set_xticks([])
        ax.set_yticks([])
        
        # Add colorbar
        cbar = self.fig.colorbar(lc, ax=ax, orientation='horizontal',
                                  fraction=0.03, pad=0.02, aspect=50)
        cbar.set_label('Speed (km/h)', color=COLORS['text'], fontsize=10)
        cbar.ax.tick_params(colors=COLORS['text'], labelsize=8)
    
    def _setup_speed_axes(self):
        """Setup the speed trace graph."""
        ax = self.ax_speed
        self._apply_style(ax, "Speed")
        
        distance = self.telemetry.distance
        speed = self.telemetry.speed
        
        # Background speed trace
        ax.fill_between(distance, 0, speed, alpha=0.2, color=COLORS['speed'])
        ax.plot(distance, speed, color=COLORS['speed'], linewidth=1, alpha=0.5)
        
        # Current position marker
        self.speed_line, = ax.plot([distance[0], distance[0]], [0, speed.max()],
                                   color=self.team_color, linewidth=2, alpha=0.8)
        self.speed_marker, = ax.plot([distance[0]], [speed[0]], 'o', 
                                     color=self.team_color, markersize=10,
                                     markeredgecolor='white', markeredgewidth=2)
        
        ax.set_xlim(distance.min(), distance.max())
        ax.set_ylim(0, speed.max() * 1.1)
        ax.set_xlabel('Distance (m)', color=COLORS['text'])
        ax.set_ylabel('km/h', color=COLORS['text'])
    
    def _setup_telemetry_panel(self):
        """Setup the live telemetry readout panel."""
        ax = self.ax_telemetry
        ax.set_facecolor(COLORS['panel_bg'])
        ax.set_xlim(0, 10)
        ax.set_ylim(0, 10)
        ax.set_xticks([])
        ax.set_yticks([])
        
        for spine in ax.spines.values():
            spine.set_color(COLORS['grid'])
        
        # Title
        ax.text(5, 9.5, "LIVE TELEMETRY", ha='center', va='top',
               color=COLORS['text'], fontsize=12, fontweight='bold')
        
        # Create telemetry readouts
        telemetry_items = [
            ('speed', 'SPEED', 'km/h', COLORS['speed'], 8.0),
            ('gear', 'GEAR', '', COLORS['gear'], 6.5),
            ('throttle', 'THROTTLE', '%', COLORS['throttle'], 5.0),
            ('brake', 'BRAKE', '%', COLORS['brake'], 3.5),
            ('rpm', 'RPM', '', COLORS['rpm'], 2.0),
        ]
        
        for key, label, unit, color, y_pos in telemetry_items:
            # Label
            ax.text(1, y_pos, label, ha='left', va='center',
                   color=color, fontsize=10, fontweight='bold')
            # Value (will be updated)
            text = ax.text(8, y_pos, "---", ha='right', va='center',
                          color='white', fontsize=14, fontweight='bold',
                          family='monospace')
            self.telemetry_texts[key] = text
            # Unit
            if unit:
                ax.text(9, y_pos, unit, ha='left', va='center',
                       color=COLORS['text'], fontsize=9, alpha=0.7)
        
        # Add DRS indicator
        ax.text(1, 0.7, 'DRS', ha='left', va='center',
               color=COLORS['drs'], fontsize=10, fontweight='bold')
        self.drs_indicator = ax.text(8, 0.7, 'OFF', ha='right', va='center',
                                     color=COLORS['text'], fontsize=12,
                                     fontweight='bold', family='monospace')
    
    def _update_frame(self, frame: int):
        """Update function called for each animation frame."""
        x = self.telemetry.x
        y = self.telemetry.y
        distance = self.telemetry.distance
        speed = self.telemetry.speed
        
        # Update car position
        self.car_marker.set_data([x[frame]], [y[frame]])
        
        # Update trail with gradient fade effect
        trail_start = max(0, frame - self.trail_length)
        
        # Update trail segments for fading effect
        num_segments = len(self.trail_segments)
        segment_length = self.trail_length // num_segments
        
        for i, segment in enumerate(self.trail_segments):
            seg_end = frame - i * segment_length
            seg_start = max(trail_start, seg_end - segment_length)
            if seg_end > seg_start >= 0:
                segment.set_data(x[seg_start:seg_end+1], y[seg_start:seg_end+1])
            else:
                segment.set_data([], [])
        
        # Main trail (kept for compatibility)
        self.trail_line.set_data(x[trail_start:frame+1], y[trail_start:frame+1])
        
        # Update speed graph marker
        self.speed_line.set_data([distance[frame], distance[frame]], 
                                 [0, speed.max()])
        self.speed_marker.set_data([distance[frame]], [speed[frame]])
        
        # Update telemetry values
        self.telemetry_texts['speed'].set_text(f"{speed[frame]:.0f}")
        self.telemetry_texts['gear'].set_text(f"{int(self.telemetry.gear[frame])}")
        self.telemetry_texts['throttle'].set_text(f"{self.telemetry.throttle[frame]:.0f}")
        self.telemetry_texts['brake'].set_text(f"{self.telemetry.brake[frame]:.0f}")
        self.telemetry_texts['rpm'].set_text(f"{int(self.telemetry.rpm[frame])}")
        
        # Update DRS indicator
        drs_active = self.telemetry.drs[frame] > 0
        self.drs_indicator.set_text('ON' if drs_active else 'OFF')
        self.drs_indicator.set_color(COLORS['drs'] if drs_active else COLORS['text'])
        
        return (self.car_marker, self.trail_line, *self.trail_segments,
                self.speed_line, self.speed_marker, 
                *self.telemetry_texts.values(), self.drs_indicator)
    
    def _on_key_press(self, event):
        """Handle keyboard controls."""
        if event.key == ' ':
            # Toggle pause
            if self.is_paused:
                self.animation.resume()
                self.is_paused = False
                print("[INFO] Animation resumed")
            else:
                self.animation.pause()
                self.is_paused = True
                print("[INFO] Animation paused")
        
        elif event.key == 'up':
            # Speed up
            self.interval_ms = max(1, int(self.interval_ms * 0.8))
            speed_factor = self.base_interval / self.interval_ms
            print(f"[INFO] Speed: {speed_factor:.2f}x")
            self._recreate_animation()
        
        elif event.key == 'down':
            # Slow down
            self.interval_ms = min(200, int(self.interval_ms * 1.25) + 1)
            speed_factor = self.base_interval / self.interval_ms
            print(f"[INFO] Speed: {speed_factor:.2f}x")
            self._recreate_animation()
        
        elif event.key == 'r':
            # Reset to start
            self.current_frame = 0
            self._recreate_animation()
            print("[INFO] Animation reset")
        
        elif event.key == 'q' or event.key == 'escape':
            # Quit animation
            plt.close(self.fig)
            print("[INFO] Animation closed")
    
    def _recreate_animation(self):
        """Recreate animation with updated interval."""
        if self.animation:
            self.animation.event_source.stop()
        
        num_frames = len(self.telemetry.x)
        self.animation = FuncAnimation(
            self.fig,
            self._update_frame,
            frames=num_frames,
            interval=self.interval_ms,
            blit=True,
            repeat=True
        )
        
        if self.is_paused:
            self.animation.pause()
    
    def run(self):
        """Start the animation."""
        num_frames = len(self.telemetry.x)
        
        self.animation = FuncAnimation(
            self.fig,
            self._update_frame,
            frames=num_frames,
            interval=self.interval_ms,
            blit=True,
            repeat=True
        )
        
        # Connect keyboard events
        self.fig.canvas.mpl_connect('key_press_event', self._on_key_press)
        
        # Add controls hint
        controls = "[SPACE] Pause/Play  |  [↑/↓] Speed  |  [R] Reset  |  [Q] Quit"
        self.fig.text(0.5, 0.02, controls, ha='center', va='bottom',
                     color=COLORS['text'], fontsize=9, alpha=0.7)
        
        print(f"[INFO] Starting animation: {num_frames} frames at {self.interval_ms}ms")
        plt.show()


def animate_lap(session, driver_code: str, drivers_info: List[dict]):
    """
    Create and run animated visualization for a driver's lap.
    
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
        driver_info = {'code': driver_code, 'team': 'Unknown'}
    
    # Get fastest lap
    lap = get_driver_fastest_lap(session, driver_code)
    if lap is None:
        print(f"[ERROR] No lap found for {driver_code}")
        return
    
    # Extract telemetry
    telemetry = extract_telemetry(lap, driver_info)
    if telemetry is None:
        print(f"[ERROR] Failed to extract telemetry for {driver_code}")
        return
    
    # Get team color
    team_color = TEAM_COLORS.get(driver_info.get('team', ''), None)
    
    # Create and run animator
    animator = TrackAnimator(telemetry, team_color)
    animator.create_figure()
    animator.run()


if __name__ == "__main__":
    print("[INFO] Track animation module loaded")
    print("[INFO] Use animate_lap(session, driver_code, drivers_info) to start animation")

