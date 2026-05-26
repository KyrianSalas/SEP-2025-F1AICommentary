from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Generator

import pandas as pd
import fastf1
import os


@dataclass
class LapSnapshot:
    """Returned by stream_race_laps for each lap."""
    driver: str
    driver_number: str
    lap_number: int
    total_laps: int  
    lap_time_s: float | None
    position: int | None
    compound: str | None
    tyre_life: int | None
    is_pit_in: bool
    is_pit_out: bool
    track_status: str | None
    sector_1_s: float | None
    sector_2_s: float | None
    sector_3_s: float | None
    telemetry_df: pd.DataFrame  
    max_speed: float


class F1TelemetryService:
    def __init__(
        self,
        log: Callable[[str], None] | None = None,
    ) -> None:
        self._log = log or (lambda _msg: None)
        cache_dir = os.getenv("FASTF1_CACHE", "./fastf1_cache")
        os.makedirs(cache_dir, exist_ok=True)
        fastf1.Cache.enable_cache(cache_dir)

        try:
            fastf1.Cache.enable_cache(cache_dir)
        except Exception:
            pass  

    def get_available_races(self, year: int) -> list[dict]:
        schedule = fastf1.get_event_schedule(year)
        races = []
        for _, event in schedule.iterrows():
            if event.get("EventFormat", "") == "testing":
                continue
            races.append({
                "year": year,
                "name": event.get("EventName", ""),
                "round": int(event.get("RoundNumber", 0)),
                "location": event.get("Location", ""),
                "date": str(event.get("EventDate", ""))[:10],
            })
        return races

    def _load_session(self, year: int, location: str, session_code: str = "R"):
        self._log(f"Loading session: {year} {location} {session_code}")
        session = fastf1.get_session(year, location, session_code)
        session.load(laps=True, telemetry=True, weather=False)
        return session

    @staticmethod
    def _resolve_driver(session, driver_input: str) -> tuple[str, str]:
        """Resolve abbreviation/number/name to (abbrev, driver_number)."""
        results = session.results
        if results is None or (hasattr(results, "empty") and results.empty):
            raise ValueError("No session results available")

        for _, row in results.iterrows():
            abbrev = str(row.get("Abbreviation", ""))
            number = str(row.get("DriverNumber", ""))
            full_name = str(row.get("FullName", ""))
            if driver_input.upper() in (abbrev.upper(), number):
                return abbrev, number
            if driver_input.lower() in full_name.lower():
                return abbrev, number

        return driver_input.upper(), driver_input

    def stream_race_laps(
        self,
        year: int,
        location: str,
        driver: str,
        offline: bool = False,
    ) -> Generator[LapSnapshot, None, None]:
        """
        Yields one LapSnapshot per lap instead of loading the whole race at once.

        Args:
            year:     Season year e.g. 2024
            location: Race location e.g. "Monza"
            driver:   Abbreviation, number, or full name e.g. "VER", "1", "Verstappen"
            offline:  If True, enables offline mode before loading — useful during
                      a live commentary session to prevent mid-race network calls.
        """
        if offline:
            # Lock to cache only — no network calls during commentary
            fastf1.Cache.offline_mode(True)
            self._log("Offline mode enabled — using cached data only")

        try:
            session = self._load_session(year, location, "R")
            abbrev, driver_number = self._resolve_driver(session, driver)
            driver_laps = session.laps.pick_drivers(abbrev)

            if driver_laps.empty:
                raise ValueError(f"No laps found for {abbrev} in {year} {location}")

            total_laps = len(driver_laps)
            self._log(f"Streaming {total_laps} laps for {abbrev} (#{driver_number})")

            for _, lap in driver_laps.iterrows():
                lap_num = int(lap["LapNumber"]) if pd.notna(lap.get("LapNumber")) else 0

                try:
                    tel = lap.get_telemetry()
                    if tel is None or tel.empty:
                        self._log(f"  Lap {lap_num}: no telemetry, skipping")
                        continue

                    if "Distance" not in tel.columns:
                        try:
                            tel = tel.add_distance()
                        except Exception:
                            pass

                    tel = tel.copy()

                except Exception as e:
                    self._log(f"  Lap {lap_num}: telemetry error ({e}), skipping")
                    continue

                max_speed = float(tel["Speed"].max()) if "Speed" in tel.columns else 0.0

                yield LapSnapshot(
                    driver=abbrev,
                    driver_number=driver_number,
                    lap_number=lap_num,
                    total_laps=total_laps,
                    lap_time_s=_safe_seconds(lap, "LapTime"),
                    position=int(lap["Position"]) if pd.notna(lap.get("Position")) else None,
                    compound=str(lap.get("Compound", "")) or None,
                    tyre_life=int(lap["TyreLife"]) if pd.notna(lap.get("TyreLife")) else None,
                    is_pit_in=bool(lap.get("PitInTime") is not None and pd.notna(lap.get("PitInTime"))),
                    is_pit_out=bool(lap.get("PitOutTime") is not None and pd.notna(lap.get("PitOutTime"))),
                    track_status=str(lap.get("TrackStatus", "")) or None,
                    sector_1_s=_safe_seconds(lap, "Sector1Time"),
                    sector_2_s=_safe_seconds(lap, "Sector2Time"),
                    sector_3_s=_safe_seconds(lap, "Sector3Time"),
                    telemetry_df=tel,
                    max_speed=round(max_speed, 2),
                )

        finally:
            if offline:
                # Always restore online mode after streaming
                fastf1.Cache.offline_mode(False)


def _safe_seconds(lap, col: str) -> float | None:
    """Safely extract a timedelta column as seconds, returning None if missing."""
    val = lap.get(col)
    if val is not None and pd.notna(val) and hasattr(val, "total_seconds"):
        return round(val.total_seconds(), 3)
    return None
