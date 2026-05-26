import json
import os
import uuid
import asyncio
import shutil
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query, HTTPException, UploadFile, File
from ..playback_engine import PlaybackEngine
from ..telemetry_loader import TelemetryLoader
from ..cache_service import CACHED_RACES, get_cached_races_payload, is_race_ready
from fastapi import HTTPException

router = APIRouter()

# csv config
CSV_DIR = os.getenv("CSV_DIR", "../telemetry/ParsedCSVs")
CSV_FILE = os.getenv("CSV_FILE", "ks_brands_hatch_legends_ford_34_coupe_23-11-2025_13-57-00.csv")

user_sessions = {}


def fetch_list_csv_files() -> list[str]:
    if not os.path.isdir(CSV_DIR):
        return []

    files = []
    for entry in os.listdir(CSV_DIR):
        if not entry.lower().endswith(".csv"):
            continue
        if entry.lower() == "sessionmeta.csv":
            continue
        full_path = os.path.join(CSV_DIR, entry)
        if os.path.isfile(full_path):
            files.append(entry)

    files.sort(key=str.lower)
    return files


def resolve_csv_filename(csv_filename: str | None = None) -> str:
    """Resolve the filename of the CSV file to be used"""
    selected = csv_filename or CSV_FILE
    basename = os.path.basename(selected)
    if basename != selected:
        raise HTTPException(status_code=400, detail="Invalid csv filename")

    full_path = os.path.join(CSV_DIR, basename)
    if not os.path.exists(full_path):
        raise HTTPException(status_code=404, detail=f"CSV file not found: {basename}")

    return basename


def fetch_telemetry_data(source="csv", year=None, location=None, session_type="R", csv_filename=None):
    if source == "csv":
        selected_csv = resolve_csv_filename(csv_filename)
        csv_path = os.path.join(CSV_DIR, selected_csv)
        print(f"Loading telemetry from CSV: {csv_path}")
        drivers_data, session_info = TelemetryLoader.load_from_csv(csv_path)
        session_info['csv_filename'] = selected_csv
        return drivers_data, session_info
    
    elif source == "fastf1":
        if year is None or location is None:
            raise ValueError("FastF1 source requires both year and location")

        normalized_location = str(location).strip()
        normalized_session_type = str(session_type).upper().strip()
        print(f"Loading telemetry from FastF1: {year} {normalized_location} {normalized_session_type}")
        return TelemetryLoader.load_from_fastf1(
            year=int(year),
            location=normalized_location,
            session_type=normalized_session_type,
            cache_path='cache'
        )
    
    else:
        raise ValueError(f"Unknown ds: {source}. Use csv or fastf1")

@router.get("/races")
async def get_races():
    if not CACHED_RACES:
        # fallback
        from ..cache_service import preload_races
        preload_races(1) # quick one year load

    return get_cached_races_payload()


@router.get("/csv/files")
async def list_csv_files():
    return {"files": fetch_list_csv_files()}


@router.post("/csv/upload")
async def upload_csv(file: UploadFile = File(...)):
    filename = os.path.basename(file.filename or "Race CSV File (Missing a name)")
    if not filename:
        raise HTTPException(status_code=400, detail="Missing file name")
    if not filename.lower().endswith(".csv"):
        raise HTTPException(status_code=400, detail="Only .csv files are supported")

    os.makedirs(CSV_DIR, exist_ok=True)
    destination_path = os.path.join(CSV_DIR, filename)

    with open(destination_path, "wb") as destination:
        shutil.copyfileobj(file.file, destination)

    return {"filename": filename}

@router.get("/session")
async def create_session(
    source: str = Query("csv"),
    year: int = Query(None),
    location: str = Query(None),
    session_type: str = Query("R"),
    csv_filename: str | None = Query(None),
):
    if source == "fastf1":
        if year is None or location is None:
            raise HTTPException(status_code=400, detail="FastF1 source requires both year and location")

        if not is_race_ready(year=year, location=location, session_type=session_type):
            raise HTTPException(status_code=409, detail="race-loading")
    elif source == "csv":
        resolve_csv_filename(csv_filename)

    session_id = str(uuid.uuid4())
    drivers_data, session_data = fetch_telemetry_data(
        source,
        year,
        location,
        session_type,
        csv_filename,
    )
    user_sessions[session_id] = {
        "engine": PlaybackEngine(drivers_data, session_data),
        "text_ws": None,
        "audio_ws": None
    }
    return {"session_id": session_id}

@router.websocket("/ws/telemetry")
async def websocket_playback(websocket: WebSocket, session_id: str = Query(...)):
    await websocket.accept()
    session = user_sessions.get(session_id)
    if not session:
        await websocket.close(code=1008)
        return
    
    session["text_ws"] = websocket
    playback_engine = session["engine"]

    try:
        initial_payload = await playback_engine.get_initial_payload()
        await websocket.send_json(initial_payload)

        while True:
            data = await websocket.receive_text()
            command = json.loads(data)
            await playback_engine.handle_command(command, websocket)

    except WebSocketDisconnect:
        session["text_ws"] = None
        _check_cleanup(session_id)

@router.websocket("/ws/commentary")
async def websocket_commentary(websocket: WebSocket, session_id: str = Query(...)):
    await websocket.accept()
    session = user_sessions.get(session_id)
    if not session:
        await websocket.close(code=1008)
        return

    playback_engine = session["engine"]
    session["audio_ws"] = websocket
    
    try:
        await playback_engine.start_live_commentary(websocket)
        while True:
            await asyncio.sleep(1)
    except WebSocketDisconnect:
        if playback_engine.commentary_service.ws:
            await playback_engine.commentary_service.ws.close()
        session["audio_ws"] = None
        _check_cleanup(session_id)

def _check_cleanup(session_id):
    session = user_sessions.get(session_id)
    if session and session["text_ws"] is None and session["audio_ws"] is None:
        asyncio.create_task(session["engine"].cleanup())
        del user_sessions[session_id]
        print(f"Session {session_id} cleaned up.")

@router.get("/")
async def working():
    return {"status": "ok"}
