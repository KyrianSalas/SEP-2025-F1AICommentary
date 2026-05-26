from dotenv import load_dotenv
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .state import active_sessions
from .api import playback_endpoints

from .cache_service import preload_races

load_dotenv() 

  # shared state dict

@asynccontextmanager
async def lifespan(app: FastAPI):
    try:
        preload_races(warm_telemetry=True, run_in_background=True)
    except Exception as e:
        print(f"Failed to preload races: {e}")
        
    yield
    print(f"Shutting down: {len(active_sessions)} engines found.")
    for session_id in list(active_sessions.keys()):
        engine = active_sessions.get(session_id)
        if engine:
            await engine.cleanup() 
            
    active_sessions.clear()
    print("All engines cleared")



app = FastAPI(title="Playback Engine API", lifespan=lifespan)

origins = ["*"]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


app.include_router(playback_endpoints.router, prefix="/api")
# app.include_router(csv_router)  # CSV endpoints
# app.include_router(f1_router)   # F1 endpoints - F1TelemetryService not implemented yet




@app.get("/")
async def root():
    return {"message": "F1 Commentary Generator API", "status": "running"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
