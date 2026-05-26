from __future__ import annotations

from .f1_telemetry_service import LapSnapshot

def build_telemetry_snapshot(lap: LapSnapshot) -> str:
    """
    Convert a LapSnapshot into a prompt 
    """
    lines = [
        f"Lap {lap.lap_number} of {lap.total_laps}",
        f"Driver: {lap.driver} (#{lap.driver_number})",
    ]

    # Position
    if lap.position:
        lines.append(f"Position: P{lap.position}")

    # Tyre info
    if lap.compound:
        tyre = f"Tyre: {lap.compound}"
        if lap.tyre_life is not None:
            tyre += f" (life: {lap.tyre_life} laps)"
        lines.append(tyre)

    # Lap time
    if lap.lap_time_s:
        lines.append(f"Lap time: {_format_laptime(lap.lap_time_s)}")

    # Sector times
    if lap.sector_1_s and lap.sector_2_s and lap.sector_3_s:
        lines.append(
            f"Sectors: S1={lap.sector_1_s:.3f}s  S2={lap.sector_2_s:.3f}s  S3={lap.sector_3_s:.3f}s"
        )

    # Pit events — high priority for commentary
    if lap.is_pit_in:
        lines.append("Event: PIT IN this lap")
    if lap.is_pit_out:
        lines.append("Event: PIT OUT this lap")

    # Track status (2=yellow, 4=SC, 5=red, 6=VSC, 7=SC ending)
    if lap.track_status and lap.track_status not in ("", "1"):
        status_label = {
            "2": "Yellow flag",
            "4": "Safety Car deployed",
            "5": "Red flag",
            "6": "Virtual Safety Car",
            "7": "Safety Car ending",
        }.get(lap.track_status, f"Track status: {lap.track_status}")
        lines.append(f"Track condition: {status_label}")

    # Telemetry stats from the DataFrame
    if not lap.telemetry_df.empty:
        tel = lap.telemetry_df
        lines.append(f"Max speed: {lap.max_speed} km/h")

        if "Throttle" in tel.columns:
            avg_throttle = tel["Throttle"].mean()
            lines.append(f"Avg throttle: {avg_throttle:.1f}%")

        if "Brake" in tel.columns:
            brake_pct = (tel["Brake"] > 0).mean() * 100
            lines.append(f"Braking: {brake_pct:.1f}% of lap")

        if "nGear" in tel.columns:
            max_gear = int(tel["nGear"].max())
            lines.append(f"Max gear: {max_gear}")

        if "DRS" in tel.columns:
            drs_pct = (tel["DRS"] >= 10).mean() * 100
            lines.append(f"DRS active: {drs_pct:.1f}% of lap")

        if "RPM" in tel.columns:
            max_rpm = int(tel["RPM"].max())
            lines.append(f"Max RPM: {max_rpm}")

    return "\n".join(lines)


def build_frontend_payload(lap: LapSnapshot) -> dict:
    """
    Serialize a LapSnapshot into a JSON-friendly dict for the frontend.

    The telemetry DataFrame is never sent — too large and not JSON serializable.
    Summary stats are extracted from it instead.
    """
    tel = lap.telemetry_df

    throttle_avg = None
    brake_pct = None
    drs_pct = None
    max_rpm = None
    max_gear = None

    if not tel.empty:
        if "Throttle" in tel.columns:
            throttle_avg = round(float(tel["Throttle"].mean()), 1)
        if "Brake" in tel.columns:
            brake_pct = round(float((tel["Brake"] > 0).mean() * 100), 1)
        if "DRS" in tel.columns:
            drs_pct = round(float((tel["DRS"] >= 10).mean() * 100), 1)
        if "RPM" in tel.columns:
            max_rpm = int(tel["RPM"].max())
        if "nGear" in tel.columns:
            max_gear = int(tel["nGear"].max())

    return {
        "type": "telemetry_update",
        "lap_number": lap.lap_number,
        "total_laps": lap.total_laps,
        "driver": lap.driver,
        "driver_number": lap.driver_number,
        "position": lap.position,
        "compound": lap.compound,
        "tyre_life": lap.tyre_life,
        "lap_time_s": lap.lap_time_s,
        "lap_time_formatted": _format_laptime(lap.lap_time_s) if lap.lap_time_s else None,
        "sector_1_s": lap.sector_1_s,
        "sector_2_s": lap.sector_2_s,
        "sector_3_s": lap.sector_3_s,
        "is_pit_in": lap.is_pit_in,
        "is_pit_out": lap.is_pit_out,
        "track_status": lap.track_status,
        "max_speed": lap.max_speed,
        "throttle_avg": throttle_avg,
        "brake_pct": brake_pct,
        "drs_pct": drs_pct,
        "max_rpm": max_rpm,
        "max_gear": max_gear,
    }


def is_notable_lap(lap: LapSnapshot, previous_lap: LapSnapshot | None = None) -> bool:
    """
    Returns True if a lap has something worth commentating beyond routine driving.
    Useful to filter out boring laps and only push interesting ones to the AI.

    A lap is notable if any of the following are true:
    - Pit in or out
    - Track status is not green
    - Position changed since last lap
    - Lap time improved by more than 0.5s vs previous lap
    - DRS was active for more than 50% of the lap
    """
    if lap.is_pit_in or lap.is_pit_out:
        return True

    if lap.track_status and lap.track_status not in ("", "1"):
        return True

    if previous_lap is not None:
        if lap.position and previous_lap.position and lap.position != previous_lap.position:
            return True

        if (
            lap.lap_time_s
            and previous_lap.lap_time_s
            and (previous_lap.lap_time_s - lap.lap_time_s) > 0.5
        ):
            return True

    if not lap.telemetry_df.empty and "DRS" in lap.telemetry_df.columns:
        drs_pct = (lap.telemetry_df["DRS"] >= 10).mean() * 100
        if drs_pct > 50:
            return True

    return False


def _format_laptime(seconds: float) -> str:
    """
    Format a lap time in seconds to a human readable string.
    e.g. 83.456 -> '1:23.456'
    """
    minutes = int(seconds // 60)
    remaining = seconds % 60
    if minutes > 0:
        return f"{minutes}:{remaining:06.3f}"
    return f"{remaining:.3f}s"
