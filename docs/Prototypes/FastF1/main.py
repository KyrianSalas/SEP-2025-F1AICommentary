#!/usr/bin/env python3
"""
main.py

F1 Telemetry Analyzer - Main Application Entry Point

A comprehensive F1 telemetry visualization tool using FastF1.
Provides interactive session selection, multi-panel dashboards,
animated track visualization, and driver comparison features.

Usage:
    python main.py

Dependencies:
    pip install fastf1 matplotlib numpy
"""

import sys
import matplotlib.pyplot as plt
from matplotlib.widgets import Button, RadioButtons

from f1_fastf1_track_demo import (
    COLORS,
    enable_cache,
    print_available_telemetry_channels,
)
from gui_selector import SessionSelector
from telemetry_visualizer import visualize_lap
from track_animation import animate_lap
from driver_comparison import compare_drivers
from sector_analysis import analyze_sectors
from lap_statistics import show_lap_stats
from corner_analysis import analyze_corners


class F1TelemetryApp:
    """
    Main application controller for F1 Telemetry Analyzer.
    
    Manages the workflow:
    1. Session selection via interactive GUI
    2. Driver selection
    3. Visualization mode selection
    4. Telemetry display/animation
    """
    
    VISUALIZATION_MODES = [
        ('Dashboard', 'View telemetry dashboard'),
        ('Animation', 'Animated track visualization'),
        ('Comparison', 'Compare two drivers'),
        ('Sectors', 'Mini-sector performance analysis'),
        ('Corners', 'Corner-by-corner analysis'),
        ('Statistics', 'Lap performance statistics'),
    ]
    
    def __init__(self):
        self.selector = SessionSelector()
        self.session = None
        self.drivers_info = []
        self.selected_drivers = []
    
    def show_welcome_screen(self):
        """Display welcome screen with app info."""
        fig, ax = plt.subplots(figsize=(12, 8))
        fig.patch.set_facecolor(COLORS['background'])
        ax.set_facecolor(COLORS['background'])
        ax.set_xlim(0, 10)
        ax.set_ylim(0, 10)
        ax.set_xticks([])
        ax.set_yticks([])
        ax.axis('off')
        
        # Decorative racing stripes
        from matplotlib.patches import Rectangle
        stripe1 = Rectangle((0, 8.8), 10, 0.15, color=COLORS['accent'], alpha=0.8)
        stripe2 = Rectangle((0, 8.5), 10, 0.15, color=COLORS['secondary'], alpha=0.6)
        ax.add_patch(stripe1)
        ax.add_patch(stripe2)
        
        # Title with shadow effect
        ax.text(5.02, 7.98, 'F1 TELEMETRY ANALYZER', ha='center', va='center',
               fontsize=32, color='#000000', fontweight='bold', alpha=0.3)
        ax.text(5, 8, 'F1 TELEMETRY ANALYZER', ha='center', va='center',
               fontsize=32, color=COLORS['accent'], fontweight='bold')
        
        # Subtitle
        ax.text(5, 7.2, 'Powered by FastF1 • Real Telemetry Data', ha='center', va='center',
               fontsize=13, color=COLORS['secondary'], style='italic')
        
        # Divider line
        ax.axhline(y=6.7, xmin=0.2, xmax=0.8, color=COLORS['grid'], linewidth=2)
        
        # Features list with icons
        features = [
            ("📊", "Interactive session and driver selection"),
            ("📈", "Comprehensive telemetry dashboard"),
            ("🏎️", "Animated track visualization with live data"),
            ("⚔️", "Head-to-head driver comparison"),
            ("🔥", "Speed heatmap overlays"),
            ("📉", "Mini-sector performance breakdown"),
        ]
        
        for i, (icon, feat) in enumerate(features):
            y = 5.8 - i*0.65
            ax.text(2.5, y, icon, ha='center', va='center', fontsize=14)
            ax.text(3, y, feat, ha='left', va='center',
                   fontsize=11, color=COLORS['text'])
        
        # Start button
        start_ax = fig.add_axes([0.35, 0.08, 0.3, 0.08])
        start_btn = Button(start_ax, 'START', color=COLORS['accent'], 
                          hovercolor=COLORS['secondary'])
        start_btn.label.set_color('white')
        start_btn.label.set_fontsize(14)
        start_btn.label.set_fontweight('bold')
        
        started = [False]
        
        def on_start(event):
            started[0] = True
            plt.close(fig)
        
        start_btn.on_clicked(on_start)
        
        plt.show()
        return started[0]
    
    def select_visualization_mode(self) -> str:
        """
        Display visualization mode selection dialog.
        
        Returns:
            Selected mode string
        """
        fig, ax = plt.subplots(figsize=(8, 6))
        fig.patch.set_facecolor(COLORS['background'])
        ax.set_facecolor(COLORS['panel_bg'])
        ax.set_axis_off()
        
        fig.suptitle('Select Visualization Mode', fontsize=16, 
                    color=COLORS['text'], fontweight='bold')
        
        mode_labels = [m[0] for m in self.VISUALIZATION_MODES]
        
        rax = fig.add_axes([0.2, 0.25, 0.6, 0.55], facecolor=COLORS['panel_bg'])
        radio = RadioButtons(rax, mode_labels, activecolor=COLORS['accent'])
        
        for label in radio.labels:
            label.set_color(COLORS['text'])
            label.set_fontsize(12)
        
        selected = [mode_labels[0]]
        
        def on_radio(label):
            selected[0] = label
        
        radio.on_clicked(on_radio)
        
        # Confirm button
        confirm_ax = fig.add_axes([0.35, 0.08, 0.3, 0.08])
        confirm_btn = Button(confirm_ax, 'Continue', color=COLORS['accent'],
                            hovercolor=COLORS['secondary'])
        confirm_btn.label.set_color('white')
        
        confirmed = [False]
        
        def on_confirm(event):
            confirmed[0] = True
            plt.close(fig)
        
        confirm_btn.on_clicked(on_confirm)
        
        plt.show()
        
        return selected[0] if confirmed[0] else None
    
    def select_second_driver(self) -> str:
        """Select second driver for comparison mode."""
        if not self.drivers_info:
            return None
        
        fig, ax = plt.subplots(figsize=(8, 10))
        fig.patch.set_facecolor(COLORS['background'])
        ax.set_facecolor(COLORS['panel_bg'])
        ax.set_axis_off()
        
        fig.suptitle('Select Second Driver for Comparison', fontsize=14,
                    color=COLORS['text'], fontweight='bold')
        
        # Filter out already selected driver
        available = [d for d in self.drivers_info 
                    if d['code'] not in self.selected_drivers]
        
        if not available:
            print("[ERROR] No other drivers available for comparison")
            plt.close(fig)
            return None
        
        driver_labels = [f"{d['code']} - {d['name']}" for d in available]
        
        rax = fig.add_axes([0.1, 0.15, 0.8, 0.75], facecolor=COLORS['panel_bg'])
        radio = RadioButtons(rax, driver_labels, activecolor=COLORS['accent'])
        
        for label in radio.labels:
            label.set_color(COLORS['text'])
            label.set_fontsize(10)
        
        selected = [available[0]['code']]
        
        def on_radio(label):
            idx = driver_labels.index(label)
            selected[0] = available[idx]['code']
        
        radio.on_clicked(on_radio)
        
        confirm_ax = fig.add_axes([0.35, 0.03, 0.3, 0.06])
        confirm_btn = Button(confirm_ax, 'Compare', color=COLORS['accent'],
                            hovercolor=COLORS['secondary'])
        confirm_btn.label.set_color('white')
        
        confirmed = [False]
        
        def on_confirm(event):
            confirmed[0] = True
            plt.close(fig)
        
        confirm_btn.on_clicked(on_confirm)
        
        plt.show()
        
        return selected[0] if confirmed[0] else None
    
    def run_visualization(self, mode: str):
        """
        Run the selected visualization mode.
        
        Args:
            mode: Visualization mode name
        """
        driver = self.selected_drivers[0] if self.selected_drivers else None
        
        if not driver:
            print("[ERROR] No driver selected")
            return
        
        if mode == 'Dashboard':
            print(f"\n[INFO] Opening dashboard for {driver}...")
            visualize_lap(self.session, driver, self.drivers_info)
        
        elif mode == 'Animation':
            print(f"\n[INFO] Starting animation for {driver}...")
            animate_lap(self.session, driver, self.drivers_info)
        
        elif mode == 'Comparison':
            # Select second driver
            second_driver = self.select_second_driver()
            if second_driver:
                print(f"\n[INFO] Comparing {driver} vs {second_driver}...")
                compare_drivers(self.session, [driver, second_driver], 
                              self.drivers_info)
            else:
                print("[INFO] Comparison cancelled")
        
        elif mode == 'Sectors':
            print(f"\n[INFO] Analyzing sectors for {driver}...")
            analyze_sectors(self.session, driver, self.drivers_info)
        
        elif mode == 'Corners':
            print(f"\n[INFO] Analyzing corners for {driver}...")
            analyze_corners(self.session, driver, self.drivers_info)
        
        elif mode == 'Statistics':
            print(f"\n[INFO] Loading statistics for {driver}...")
            show_lap_stats(self.session, driver, self.drivers_info)
    
    def run(self):
        """Run the main application loop."""
        print("\n" + "="*60)
        print("  F1 TELEMETRY ANALYZER")
        print("  Powered by FastF1")
        print("="*60)
        
        # Enable cache
        enable_cache()
        print_available_telemetry_channels()
        
        # Show welcome screen
        if not self.show_welcome_screen():
            print("[INFO] Exited")
            return
        
        # Session selection workflow
        if not self.selector.run_full_selection():
            print("[INFO] Selection cancelled")
            return
        
        self.session = self.selector.session
        self.drivers_info = self.selector.drivers
        self.selected_drivers = self.selector.selected_drivers
        
        # Visualization mode loop
        while True:
            mode = self.select_visualization_mode()
            
            if mode is None:
                print("[INFO] Exiting...")
                break
            
            print(f"[INFO] Selected mode: {mode}")
            self.run_visualization(mode)
            
            # Ask to continue
            print("\n[INFO] Close the visualization window to continue or select a new mode")


def main():
    """Application entry point."""
    try:
        app = F1TelemetryApp()
        app.run()
    except KeyboardInterrupt:
        print("\n[INFO] Interrupted by user")
        sys.exit(0)
    except Exception as e:
        print(f"\n[ERROR] {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()

