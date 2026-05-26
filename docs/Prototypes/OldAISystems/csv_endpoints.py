# from fastapi import APIRouter, HTTPException
# from fastapi.responses import StreamingResponse
# # from models.commentary_models import CommentaryRequest, CommentaryResponse
# from fast_app.services.commentary_service import CommentaryService
# from fast_app.services.csv_telemetry_service import CSVTelemetryService, list_available_csvs, parse_csv_filename
# import time
# import os

# router = APIRouter(prefix="/api", tags=["commentary"])

# commentary_service = CommentaryService()

# CSV_BASE_PATH = os.getenv(
#     "CSV_PATH",
#     os.path.join(os.getcwd(), "telemetry", "ParsedCSVs")
# )


# @router.get("/csv/races")
# async def get_available_races():
#     """
#     Get list of available race CSV files
    
#     Returns:
#     {
#       "races": [
#         {
#           "filename": "ks_brands_hatch_ac_legends_bmw_csl_10-10-2025_21-12-00.csv",
#           "venue": "ks_brands_hatch",
#           "vehicle": "ac_legends_bmw_csl",
#           "date": "10-10-2025",
#           "time": "21-12-00"
#         }
#       ]
#     }
#     """
#     try:
#         csv_files = list_available_csvs(CSV_BASE_PATH)
        
#         # Parse metadata from filenames
#         races = []
#         for filename in csv_files:
#             metadata = parse_csv_filename(filename)
#             races.append({
#                 "filename": filename,
#                 "venue": metadata["venue"],
#                 "vehicle": metadata["vehicle"],
#                 "date": metadata["date"],
#                 "time": metadata["time"]
#             })
        
#         return {"races": races}
#     except Exception as e:
#         raise HTTPException(status_code=500, detail=f"Error listing races: {str(e)}")


# @router.get("/csv/telemetry/{filename}/{time_seconds}")
# async def get_telemetry_at_time(filename: str, time_seconds: float):
#     """
#     Get telemetry data at a specific time from a race CSV
    
#     """
#     try:
#         csv_path = os.path.join(CSV_BASE_PATH, filename)
        
#         if not os.path.exists(csv_path):
#             raise HTTPException(status_code=404, detail=f"CSV file not found: {filename}")
        
#         # Load telemetry service for this CSV
#         telemetry_service = CSVTelemetryService(csv_path)
        
#         # Get telemetry at the specified time
#         telemetry = telemetry_service.get_telemetry_at_time(time_seconds)
        
#         return telemetry
        
#     except FileNotFoundError as e:
#         raise HTTPException(status_code=404, detail=str(e))
#     except ValueError as e:
#         raise HTTPException(status_code=400, detail=str(e))
#     except Exception as e:
#         raise HTTPException(status_code=500, detail=f"Error retrieving telemetry: {str(e)}")


# @router.post("/csv/generate")
# async def generate_commentary_from_csv(
#     filename: str,
#     time_seconds: float,
#     commentary_style: str = "crofty",
#     context: str = None
# ):
#     """
#     Generate commentary from a specific moment in a recorded race CSV
    
#     Example POST body:
#     {
#       "filename": "ks_brands_hatch_ac_legends_bmw_csl_10-10-2025_21-12-00.csv",
#       "time_seconds": 45.5,
#       "commentary_style": "brundle",
#       "context": "Approaching final corner"
#     }
    
#     Returns: CommentaryResponse with generated commentary
#     {
#       "commentary": "As a driver, you're committed here at 280 km/h...",
#       "timestamp": 1705523694.5,
#       "style": "brundle"
#     }
#     """
#     try:
#         csv_path = os.path.join(CSV_BASE_PATH, filename)
        
#         if not os.path.exists(csv_path):
#             raise HTTPException(status_code=404, detail=f"CSV file not found: {filename}")
        
#         # Load telemetry from CSV
#         telemetry_service = CSVTelemetryService(csv_path)
#         telemetry = telemetry_service.get_telemetry_at_time(time_seconds)
        
#         # Generate commentary
#         commentary = commentary_service.generate_commentary(
#             telemetry=telemetry,
#             style=commentary_style,
#             context=context
#         )
        
#         return CommentaryResponse(
#             commentary=commentary,
#             timestamp=time.time(),
#             style=commentary_style
#         )
        
#     except FileNotFoundError as e:
#         raise HTTPException(status_code=404, detail=str(e))
#     except ValueError as e:
#         raise HTTPException(status_code=400, detail=str(e))
#     except Exception as e:
#         raise HTTPException(status_code=500, detail=f"Error generating commentary: {str(e)}")