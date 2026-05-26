import asyncio
import pandas as pd
import numpy as np
from .services.commentary_generator import RealtimeCommentaryGenerator
from .services.f1_telemetry_service import LapSnapshot
from .services.build_f1_telemetry import build_telemetry_snapshot, is_notable_lap

class PlaybackEngine:
    def __init__(self, drivers_data: dict, session_info: dict):
        self.drivers_data = drivers_data
        self.session_info = session_info
        self._driver_metadata = session_info.get("driver_metadata", {})
        self.is_playing = False
        self.current_index = 0
        self.playback_speed = 1.0
        self._is_fastf1 = session_info.get('source') == 'fastf1'

        # Lap boundary tracking (FastF1 only)
        self._last_lap_per_driver: dict[str, int] = {}
        self._lap_start_index_per_driver: dict[str, int] = {}
        self._prev_lap_snapshot_per_driver: dict[str, LapSnapshot] = {}

        self.commentary_service = RealtimeCommentaryGenerator()
        self.main_loop_task = None
        self.commentary_listener_task = None

    @staticmethod
    def _first_available_value(row, candidates, default=0):
        """Return the first available value from candidate columns for mixed data sources."""
        for col in candidates:
            if col in row.index and pd.notna(row[col]):
                return row[col]
        return default

    def _build_commentary_snapshot(self, row, prefix="Time", driver_code=None, race_position=None, total_cars=None):
        time_val = self._first_available_value(row, ["Time_s", "Time (s)"], 0)
        speed_val = self._first_available_value(row, ["Ground Speed (km/h)", "Speed", "SpeedI1"], 0)
        gear_val = self._first_available_value(row, ["Gear", "nGear"], "N/A")
        lap_val = self._first_available_value(row, ["Session Lap Count", "LapNumber"], 1)
        throttle_val = self._first_available_value(row, ["Throttle", "Throttle Pos (%)"], None)
        drs_val = self._first_available_value(row, ["DRS"], None)
        rpm_val = self._first_available_value(row, ["RPM", "Engine RPM (rpm)"], None)

        base = f"{prefix}: {time_val}s, Speed: {speed_val:.0f}km/h, Gear: {gear_val}, Lap: {lap_val}"

        extras = []
        if driver_code:
            extras.append(f"Driver: {driver_code}")
        if race_position and total_cars:
            extras.append(f"P{race_position}/{total_cars}")
        if rpm_val is not None:
            extras.append(f"RPM: {int(rpm_val)}")
        if throttle_val is not None:
            extras.append(f"Throttle: {throttle_val:.0f}%")
        if drs_val is not None and float(drs_val) >= 10:
            extras.append("DRS: OPEN")

        return (base + ", " + ", ".join(extras)) if extras else base

    @staticmethod
    def _ordinal(position: int) -> str:
        if 10 <= (position % 100) <= 20:
            suffix = "th"
        else:
            suffix = {1: "st", 2: "nd", 3: "rd"}.get(position % 10, "th")
        return f"{position}{suffix}"

    def _check_lap_boundaries(self, rows_by_driver: dict, positions: dict) -> list[LapSnapshot]:
        """
        For each driver, detect if the lap number just incremented.
        Returns a list of LapSnapshots for completed laps, sorted by race position
        (P1 first) so the caller can pick the most prominent one to commentate on.
        """
        total_laps = int(self.session_info.get('TotalLapCount', 0))
        completed: list[tuple[int, LapSnapshot]] = []  # (race_position, snapshot)

        for driver_code, row in rows_by_driver.items():
            lap_num = int(self._first_available_value(row, ["Session Lap Count", "LapNumber"], 0) or 0)
            last_lap = self._last_lap_per_driver.get(driver_code, 0)

            if last_lap == 0:
                # First frame for this driver — just record start position
                self._lap_start_index_per_driver[driver_code] = self.current_index
                self._last_lap_per_driver[driver_code] = lap_num
                continue

            if lap_num != last_lap:
                # Lap just completed — slice the driver's telemetry for that lap
                lap_start = self._lap_start_index_per_driver.get(driver_code, 0)
                df = self.drivers_data[driver_code]
                lap_df = df.iloc[lap_start:self.current_index].copy()

                if not lap_df.empty:
                    max_speed = float(lap_df['Speed'].max()) if 'Speed' in lap_df.columns else 0.0

                    lap_time_s = None
                    if 'Time_s' in lap_df.columns:
                        t0 = float(lap_df['Time_s'].iloc[0])
                        t1 = float(lap_df['Time_s'].iloc[-1])
                        if t1 > t0:
                            lap_time_s = round(t1 - t0, 3)

                    race_pos = positions.get(driver_code)
                    snapshot = LapSnapshot(
                        driver=driver_code,
                        driver_number=driver_code,
                        lap_number=last_lap,
                        total_laps=total_laps,
                        lap_time_s=lap_time_s,
                        position=race_pos,
                        compound=None,
                        tyre_life=None,
                        is_pit_in=False,
                        is_pit_out=False,
                        track_status=None,
                        sector_1_s=None,
                        sector_2_s=None,
                        sector_3_s=None,
                        telemetry_df=lap_df,
                        max_speed=max_speed,
                    )
                    prev = self._prev_lap_snapshot_per_driver.get(driver_code)
                    if is_notable_lap(snapshot, prev):
                        completed.append((race_pos or 99, snapshot))
                    self._prev_lap_snapshot_per_driver[driver_code] = snapshot

                self._lap_start_index_per_driver[driver_code] = self.current_index

            self._last_lap_per_driver[driver_code] = lap_num

        # Return sorted by position so P1 is first
        completed.sort(key=lambda x: x[0])
        return [snap for _, snap in completed]

    def _calculate_positions(self, rows_by_driver: dict) -> dict:
        """Rank drivers by lap progress then distance to produce live position."""
        ranked = []
        for driver_code, row in rows_by_driver.items():
            lap = int(self._first_available_value(row, ["Session Lap Count", "LapNumber"], 0) or 0)
            distance = float(self._first_available_value(row, ["Distance"], 0.0) or 0.0)
            ranked.append((driver_code, lap, distance))

        ranked.sort(key=lambda item: (item[1], item[2]), reverse=True)
        return {driver_code: idx + 1 for idx, (driver_code, _, _) in enumerate(ranked)}

    def _attach_driver_metadata(self, clean_row: dict, driver_code: str) -> None:
        metadata = self._driver_metadata.get(driver_code, {})

        team_name = metadata.get("team_name")
        if team_name:
            clean_row["team_name"] = team_name

        driver_name = metadata.get("driver_name")
        if driver_name:
            clean_row["driver_name"] = driver_name

        driver_number = metadata.get("driver_number")
        if driver_number:
            clean_row["driver_number"] = driver_number

    async def get_initial_payload(self):
        first_driver_code = next(iter(self.drivers_data))
        first_driver_df = self.drivers_data[first_driver_code]
        track_df = first_driver_df
        print(track_df.columns)
        best_lap_number = self.session_info.get("best_lap_number")
        if best_lap_number is not None and 'Session Lap Count' in track_df.columns:
            filtered_df = track_df[track_df['Session Lap Count'] == best_lap_number]
            if not filtered_df.empty:
                track_df = filtered_df
        
        track_layout = track_df[['X', 'Y']].iloc[::10].to_dict('records')
        
        print(f"Sent initial metadata for drivers: {list(self.drivers_data.keys())}")
        
        return {
            "type": "initial_setup",
            "session_info": self.session_info,
            "track_map": track_layout,
            "total_points": len(first_driver_df),
            "available_drivers": list(self.drivers_data.keys())
        }
    
    async def handle_command(self, command, websocket):
        """Handles incoming commands to control playback.

        Args:
            command: A dictionary containing the command and its parameters.
            websocket: The WebSocket connection to send data through.
        Returns:
            None

        """
        action = command.get("action")
        if action == "play":
            speed = command.get("playback_speed", 1.0)
            await self._play(websocket, playback_speed=speed)
        elif action == "pause":
            self._pause()
        elif action == "reset":
            self._reset()
        elif action == "change_speed":
            new_speed = command.get("playback_speed", 1.0)
            self._change_speed(new_speed)
        elif action == "seek":
            index = command.get("index", 0)
            self._seek(websocket, index)
        elif action == "playback_finished":
            self.commentary_service.is_speaking = False
        else:
            print(f"Unknown command received, action: {action}")

    async def start_live_commentary(self, frontend_ws):
        """Starts the AI connection and the listener task."""
        await self.commentary_service.connect()
        self.commentary_listener_task = asyncio.create_task(
            self.commentary_service.listen_for_ai_responses(frontend_ws)
            )
            
        await frontend_ws.send_json({"type": "ai_status", "status": "connected"})
    
    async def _playback_loop(self, telemetry_ws):
        total_points = max(len(df) for df in self.drivers_data.values())
        first_df = max(self.drivers_data.values(), key=len)
        
        while self.is_playing and self.current_index < total_points:
            updates = []
            rows_by_driver = {}
            for driver_code, df in self.drivers_data.items():
                if self.current_index >= len(df):
                    continue
                row = df.iloc[self.current_index]
                rows_by_driver[driver_code] = row
                clean_row = self.make_json_safe(row.to_dict())
                clean_row['driver_code'] = driver_code
                self._attach_driver_metadata(clean_row, driver_code)
                updates.append(clean_row)

            if not updates:
                break

            positions = self._calculate_positions(rows_by_driver)
            total_cars = len(positions)
            for clean_row in updates:
                driver_code = clean_row['driver_code']
                race_position = positions.get(driver_code)
                clean_row['race_position'] = race_position
                clean_row['position_text'] = self._ordinal(race_position) if race_position is not None else None
                clean_row['field_size'] = total_cars

            await telemetry_ws.send_json({
                "type": "multi_telemetry_update",
                "index": self.current_index,
                "total_points": total_points,
                "drivers": updates
            })

            # FastF1: push rich lap summary at each lap boundary
            if self._is_fastf1:
                notable_laps = self._check_lap_boundaries(rows_by_driver, positions)
                if notable_laps and not self.commentary_service.is_speaking:
                    rich_prompt = build_telemetry_snapshot(notable_laps[0])
                    print(f"[LapCommentary] Lap {notable_laps[0].lap_number} – {notable_laps[0].driver}")
                    asyncio.create_task(self.commentary_service.push_telemetry(rich_prompt))

            if self.current_index % 20 == 0 and not self.commentary_service.is_speaking:
                current_row = first_df.iloc[self.current_index]
                snapshot = self._build_commentary_snapshot(current_row, prefix="Time")

                brake_val = self._first_available_value(
                    current_row,
                    ["Brake Pos (%)", "Brake"],
                    0,
                )
                # CSV: Brake Pos (%) is 0-100; FastF1: Brake is 0.0-1.0 pressure
                brake_threshold = 90 if "Brake Pos (%)" in current_row.index else 0.9
                if brake_val > brake_threshold:
                    snapshot += " | CRITICAL: Massive braking into the corner!"
                
                asyncio.create_task(self.commentary_service.push_telemetry(snapshot))

            delay = 0.1 / self.playback_speed
            self.current_index += 1
            await asyncio.sleep(max(0.001, delay))

    async def _send_line(self, telemetry_ws):
        # run a single iteration of the playback loop
        total_points = max(len(df) for df in self.drivers_data.values())
        updates = []
        rows_by_driver = {}
        for driver_code, df in self.drivers_data.items():
            if self.current_index >= len(df):
                continue
            row = df.iloc[self.current_index]
            rows_by_driver[driver_code] = row
            clean_row = self.make_json_safe(row.to_dict())
            clean_row['driver_code'] = driver_code
            self._attach_driver_metadata(clean_row, driver_code)
            updates.append(clean_row)

        if not updates:
            return

        positions = self._calculate_positions(rows_by_driver)
        total_cars = len(positions)
        for clean_row in updates:
            driver_code = clean_row['driver_code']
            race_position = positions.get(driver_code)
            clean_row['race_position'] = race_position
            clean_row['position_text'] = self._ordinal(race_position) if race_position is not None else None
            clean_row['field_size'] = total_cars

        await telemetry_ws.send_json({
            "type": "multi_telemetry_update",
            "index": self.current_index,
            "total_points": total_points,
            "drivers": updates
        })

    def make_json_safe(self, data):
        """
        Recursively converts a dictionary or value into a json-serialisable format.
        Handles Timestamps, NaNs, Numpy types, and Booleans.
        """
        if isinstance(data, dict):
            return {k: self.make_json_safe(v) for k, v in data.items()}
        if isinstance(data, list):
            return [self.make_json_safe(v) for v in data]
        if isinstance(data, (pd.Timestamp, np.datetime64)):
            return str(data)
        if isinstance(data, (pd.Timedelta, np.timedelta64)):
            return data.total_seconds()
        if isinstance(data, (bool, np.bool_)):
            return bool(data)
        if isinstance(data, (float, np.float64, np.float32)):
            # Return None for NaN/Inf so the frontend falls back to the last
            # valid reading instead of treating 0 as a real value.
            return float(data) if np.isfinite(data) else None
        if isinstance(data, (int, np.int64, np.int32)):
            return int(data)
        if pd.isna(data):
            return None
        return data

    async def cleanup(self):
        """Need these for async stuff"""
        self.is_playing = False
        if self.main_loop_task: 
            self.main_loop_task.cancel()
        if self.commentary_listener_task: 
            self.commentary_listener_task.cancel()
        if self.commentary_service.ws: 
            await self.commentary_service.ws.close()
        await asyncio.sleep(0.1)

    async def _play(self, websocket, playback_speed=1.0):
        """Starts or resumes playback.

        Args:
            websocket: The WebSocket connection to send data through.
            playback_speed: Speed multiplier for playback.
        Returns:
            None

        """
        self.playback_speed = playback_speed
        self.commentary_service.paused = False
        if not self.is_playing:
            self.is_playing = True
            self.main_loop_task = asyncio.create_task(self._playback_loop(websocket))
            print(f"Playback started at {self.playback_speed}x speed.")
            if self.current_index % 20 == 0:
                first_df = next(iter(self.drivers_data.values()))
                row = first_df.iloc[self.current_index]
                time_val = self._first_available_value(row, ["Time_s", "Time (s)"], 0)
                speed_val = self._first_available_value(
                    row,
                    ["Ground Speed (km/h)", "Speed", "SpeedI1"],
                    0,
                )
                snapshot = f"Resuming. Time {time_val}s, Speed {speed_val} km/h."
                asyncio.create_task(self.commentary_service.push_telemetry(snapshot))

    def _pause(self):
        """Pauses the playback.

        Args:
            None
        Returns:
            None

        """
        if self.is_playing:
            self.is_playing = False
            if self.main_loop_task:
                self.main_loop_task.cancel()

            self.commentary_service.paused = True
            print("Playback paused.")

    def _reset(self):
        """Resets the playback to the beginning.

        Args:
            None
        Returns:
            None

        """
        self._pause()
        self.current_index = 0
        self._last_lap_per_driver.clear()
        self._lap_start_index_per_driver.clear()
        self._prev_lap_snapshot_per_driver.clear()
        print("Playback reset.")

    def _change_speed(self, new_speed):
        """Changes the playback speed.

        Args:
            new_speed: The new speed multiplier for playback.
        Returns:
            None

        """
        self.playback_speed = new_speed
        print(f"Playback speed changed to {self.playback_speed}x.")

    def _seek(self, telemetry_ws, index):
        """Seeks to a specific index in the data.

        Args:
            index: The index to seek to.
        Returns:
            None

        """
        total_points = max(len(df) for df in self.drivers_data.values())
        if 0 <= index < total_points:
            self.current_index = index
            print(f"Seeked to index {self.current_index}.")
        else:
            print("Seek index out of bounds.")

        # Push new frame if paused
        if (not self.is_playing):
            asyncio.create_task(self._send_line(telemetry_ws))
            
