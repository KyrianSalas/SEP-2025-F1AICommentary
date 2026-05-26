#!/usr/bin/env python3
"""
gui_selector.py

Interactive GUI for selecting F1 sessions and drivers using matplotlib widgets.
Provides a user-friendly interface to browse seasons, races, and drivers.
"""

import sys
from typing import Callable, Dict, List, Optional

import matplotlib.pyplot as plt
from matplotlib.widgets import Button, RadioButtons
import matplotlib.patches as mpatches

# Import core data module
from f1_fastf1_track_demo import (
    COLORS,
    TEAM_COLORS,
    enable_cache,
    get_available_seasons,
    get_season_schedule,
    get_session_drivers,
    load_session,
)


class SessionSelector:
    """
    Interactive GUI for selecting F1 session and driver.
    
    Provides a step-by-step selection process:
    1. Select season year
    2. Select Grand Prix
    3. Select session type (Race, Qualifying, Practice)
    4. Select driver(s)
    """
    
    SESSION_TYPES = [
        ('Race', 'R'),
        ('Qualifying', 'Q'),
        ('Sprint', 'S'),
        ('Sprint Qualifying', 'SQ'),
        ('Practice 1', 'FP1'),
        ('Practice 2', 'FP2'),
        ('Practice 3', 'FP3'),
    ]
    
    def __init__(self):
        self.selected_year: Optional[int] = None
        self.selected_gp: Optional[Dict] = None
        self.selected_session_type: Optional[str] = None
        self.selected_drivers: List[str] = []
        self.session = None
        self.schedule: List[Dict] = []
        self.drivers: List[Dict] = []
        
        # Callback for when selection is complete
        self.on_complete: Optional[Callable] = None
        
    def _setup_figure_style(self, fig):
        """Apply dark theme styling to figure."""
        fig.patch.set_facecolor(COLORS['background'])
        
    def _setup_axes_style(self, ax):
        """Apply dark theme styling to axes."""
        ax.set_facecolor(COLORS['panel_bg'])
        ax.tick_params(colors=COLORS['text'])
        ax.xaxis.label.set_color(COLORS['text'])
        ax.yaxis.label.set_color(COLORS['text'])
        ax.title.set_color(COLORS['text'])
        for spine in ax.spines.values():
            spine.set_color(COLORS['grid'])
    
    def select_season(self) -> Optional[int]:
        """
        Display season selection dialog.
        
        Returns:
            Selected year or None if cancelled
        """
        seasons = get_available_seasons()
        
        fig, ax = plt.subplots(figsize=(6, 8))
        self._setup_figure_style(fig)
        self._setup_axes_style(ax)
        
        fig.suptitle('Select F1 Season', fontsize=16, color=COLORS['text'], fontweight='bold')
        ax.set_axis_off()
        
        # Create radio buttons for seasons
        rax = fig.add_axes([0.3, 0.15, 0.4, 0.7], facecolor=COLORS['panel_bg'])
        radio = RadioButtons(rax, [str(s) for s in seasons], activecolor=COLORS['accent'])
        
        # Style radio buttons
        for label in radio.labels:
            label.set_color(COLORS['text'])
            label.set_fontsize(12)
        
        selected = [seasons[0]]  # Default selection
        
        def on_radio(label):
            selected[0] = int(label)
        
        radio.on_clicked(on_radio)
        
        # Confirm button
        confirm_ax = fig.add_axes([0.35, 0.02, 0.3, 0.06])
        confirm_btn = Button(confirm_ax, 'Confirm', color=COLORS['accent'], hovercolor=COLORS['secondary'])
        confirm_btn.label.set_color(COLORS['text'])
        
        confirmed = [False]
        
        def on_confirm(event):
            confirmed[0] = True
            plt.close(fig)
        
        confirm_btn.on_clicked(on_confirm)
        
        plt.show()
        
        if confirmed[0]:
            self.selected_year = selected[0]
            return self.selected_year
        return None
    
    def select_grand_prix(self) -> Optional[Dict]:
        """
        Display Grand Prix selection dialog.
        
        Returns:
            Selected GP dict or None if cancelled
        """
        if self.selected_year is None:
            print("[ERROR] Must select season first")
            return None
        
        print(f"[INFO] Fetching {self.selected_year} schedule...")
        self.schedule = get_season_schedule(self.selected_year)
        
        if not self.schedule:
            print("[ERROR] No events found for this season")
            return None
        
        fig, ax = plt.subplots(figsize=(10, 12))
        self._setup_figure_style(fig)
        self._setup_axes_style(ax)
        
        fig.suptitle(f'{self.selected_year} Grand Prix Selection', 
                     fontsize=16, color=COLORS['text'], fontweight='bold')
        ax.set_axis_off()
        
        # Create scrollable list using radio buttons
        gp_names = [f"{gp['round']:2d}. {gp['name']}" for gp in self.schedule]
        
        rax = fig.add_axes([0.1, 0.1, 0.8, 0.8], facecolor=COLORS['panel_bg'])
        radio = RadioButtons(rax, gp_names, activecolor=COLORS['accent'])
        
        for label in radio.labels:
            label.set_color(COLORS['text'])
            label.set_fontsize(10)
        
        selected = [self.schedule[0]]
        
        def on_radio(label):
            idx = gp_names.index(label)
            selected[0] = self.schedule[idx]
        
        radio.on_clicked(on_radio)
        
        # Confirm button
        confirm_ax = fig.add_axes([0.35, 0.02, 0.3, 0.05])
        confirm_btn = Button(confirm_ax, 'Confirm', color=COLORS['accent'], hovercolor=COLORS['secondary'])
        confirm_btn.label.set_color(COLORS['text'])
        
        confirmed = [False]
        
        def on_confirm(event):
            confirmed[0] = True
            plt.close(fig)
        
        confirm_btn.on_clicked(on_confirm)
        
        plt.show()
        
        if confirmed[0]:
            self.selected_gp = selected[0]
            return self.selected_gp
        return None
    
    def select_session_type(self) -> Optional[str]:
        """
        Display session type selection dialog.
        
        Returns:
            Selected session code or None if cancelled
        """
        fig, ax = plt.subplots(figsize=(6, 6))
        self._setup_figure_style(fig)
        self._setup_axes_style(ax)
        
        gp_name = self.selected_gp['name'] if self.selected_gp else 'Unknown'
        fig.suptitle(f'Select Session - {gp_name}', 
                     fontsize=14, color=COLORS['text'], fontweight='bold')
        ax.set_axis_off()
        
        session_labels = [s[0] for s in self.SESSION_TYPES]
        
        rax = fig.add_axes([0.3, 0.2, 0.4, 0.6], facecolor=COLORS['panel_bg'])
        radio = RadioButtons(rax, session_labels, activecolor=COLORS['accent'])
        
        for label in radio.labels:
            label.set_color(COLORS['text'])
            label.set_fontsize(12)
        
        selected = [self.SESSION_TYPES[0][1]]  # Default to Race
        
        def on_radio(label):
            for name, code in self.SESSION_TYPES:
                if name == label:
                    selected[0] = code
                    break
        
        radio.on_clicked(on_radio)
        
        # Confirm button
        confirm_ax = fig.add_axes([0.35, 0.05, 0.3, 0.08])
        confirm_btn = Button(confirm_ax, 'Load Session', color=COLORS['accent'], hovercolor=COLORS['secondary'])
        confirm_btn.label.set_color(COLORS['text'])
        
        confirmed = [False]
        
        def on_confirm(event):
            confirmed[0] = True
            plt.close(fig)
        
        confirm_btn.on_clicked(on_confirm)
        
        plt.show()
        
        if confirmed[0]:
            self.selected_session_type = selected[0]
            return self.selected_session_type
        return None
    
    def load_selected_session(self) -> bool:
        """
        Load the selected session from FastF1.
        
        Returns:
            True if session loaded successfully
        """
        if not all([self.selected_year, self.selected_gp, self.selected_session_type]):
            print("[ERROR] Complete selection first")
            return False
        
        self.session = load_session(
            self.selected_year,
            self.selected_gp['name'],
            self.selected_session_type
        )
        
        if self.session:
            self.drivers = get_session_drivers(self.session)
            return True
        return False
    
    def select_drivers(self, multi_select: bool = True) -> List[str]:
        """
        Display driver selection dialog.
        
        Args:
            multi_select: Allow selecting multiple drivers for comparison
            
        Returns:
            List of selected driver codes
        """
        if not self.drivers:
            print("[ERROR] Load session first to get driver list")
            return []
        
        fig, ax = plt.subplots(figsize=(8, 10))
        self._setup_figure_style(fig)
        self._setup_axes_style(ax)
        
        fig.suptitle('Select Driver(s)', fontsize=16, color=COLORS['text'], fontweight='bold')
        ax.set_axis_off()
        
        # Create driver list
        driver_labels = [f"{d['code']} - {d['name']} ({d['team']})" for d in self.drivers]
        
        rax = fig.add_axes([0.1, 0.15, 0.8, 0.75], facecolor=COLORS['panel_bg'])
        radio = RadioButtons(rax, driver_labels, activecolor=COLORS['accent'])
        
        for i, label in enumerate(radio.labels):
            label.set_color(COLORS['text'])
            label.set_fontsize(10)
            # Add team colour indicator
            team = self.drivers[i]['team']
            color = TEAM_COLORS.get(team, COLORS['secondary'])
            label.set_color(color)
        
        selected = [self.drivers[0]['code']]
        
        def on_radio(label):
            idx = driver_labels.index(label)
            selected[0] = self.drivers[idx]['code']
        
        radio.on_clicked(on_radio)
        
        # Confirm button
        confirm_ax = fig.add_axes([0.35, 0.02, 0.3, 0.06])
        confirm_btn = Button(confirm_ax, 'Confirm', color=COLORS['accent'], hovercolor=COLORS['secondary'])
        confirm_btn.label.set_color(COLORS['text'])
        
        confirmed = [False]
        
        def on_confirm(event):
            confirmed[0] = True
            plt.close(fig)
        
        confirm_btn.on_clicked(on_confirm)
        
        plt.show()
        
        if confirmed[0]:
            self.selected_drivers = [selected[0]]
            return self.selected_drivers
        return []
    
    def run_full_selection(self) -> bool:
        """
        Run the complete selection workflow.
        
        Returns:
            True if selection completed successfully
        """
        print("\n" + "="*60)
        print("  F1 TELEMETRY ANALYZER - Session Selection")
        print("="*60 + "\n")
        
        # Step 1: Season
        if not self.select_season():
            print("[INFO] Selection cancelled")
            return False
        print(f"[OK] Selected season: {self.selected_year}")
        
        # Step 2: Grand Prix
        if not self.select_grand_prix():
            print("[INFO] Selection cancelled")
            return False
        print(f"[OK] Selected GP: {self.selected_gp['name']}")
        
        # Step 3: Session type
        if not self.select_session_type():
            print("[INFO] Selection cancelled")
            return False
        print(f"[OK] Selected session: {self.selected_session_type}")
        
        # Step 4: Load session
        print("\n[INFO] Loading session data from FastF1...")
        if not self.load_selected_session():
            print("[ERROR] Failed to load session")
            return False
        print(f"[OK] Session loaded with {len(self.drivers)} drivers")
        
        # Step 5: Select driver(s)
        if not self.select_drivers():
            print("[INFO] Selection cancelled")
            return False
        print(f"[OK] Selected driver(s): {', '.join(self.selected_drivers)}")
        
        return True


def main():
    """Run the interactive session selector."""
    enable_cache()
    
    selector = SessionSelector()
    
    if selector.run_full_selection():
        print("\n" + "="*60)
        print("  SELECTION COMPLETE")
        print("="*60)
        print(f"  Year:     {selector.selected_year}")
        print(f"  GP:       {selector.selected_gp['name']}")
        print(f"  Session:  {selector.selected_session_type}")
        print(f"  Driver:   {', '.join(selector.selected_drivers)}")
        print("="*60 + "\n")
        
        # Return session and drivers for visualization
        return selector.session, selector.selected_drivers, selector.drivers
    
    return None, [], []


if __name__ == "__main__":
    session, selected_drivers, all_drivers = main()
    if session:
        print("[INFO] Ready to visualize telemetry data")

