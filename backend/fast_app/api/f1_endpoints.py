# from fastapi import APIRouter, HTTPException
# from models.commentary_models import CommentaryResponse
# from services.commentary_service import CommentaryService
# from services.f1_telemetry_service import F1TelemetryService
# import time

# router = APIRouter(prefix="/api/f1", tags=["f1-commentary"])

# commentary_service = CommentaryService()
# f1_service = F1TelemetryService()


# @router.get("/races/{year}")
# async def get_f1_races(year: int):
#     """
#     getts a list of all f1 races in a given year
#     Returns:
#     {
#       "year": 2024,
#       "races": [        
#         {
#             "year": 2024,
#             "name": "Bahrain Grand Prix",
#             "round": 1,
#             "date": "2024-03-03"
#         },
#         ...
#       ]
#     }
#     """ 

#     try:
#         races = f1_service.get_available_races(year)
#         return {"year": year, "races": races}
#     except Exception as e:
#         raise HTTPException(status_code=500, detail=f"Error fetching races: {str(e)}")


# @router.post("/load-session")
# async def load_f1_session(year: int, race: str, session_type: str = "R"):
#     """
#     Loads a session data to query telemetry 
#     """

#     try:
#         f1_service.load_session(year, race, session_type)
#         return {
#             "message": "Session loaded successfully",
#             "year": year,
#             "race": race,
#             "session_type": session_type
#         }
#     except Exception as e:
#         raise HTTPException(status_code=500, detail=f"Error loading session: {str(e)}")


# @router.get("/drivers")
# async def get_drivers():
#     """
#     Gets a list of available drivers in the loaded sessiong    
#     Returns:
#     {
#       "drivers": [
#         {
#           "number": "44",
#           "abbreviation": "HAM",
#           "full_name": "Lewis Hamilton",
#           "team": "Mercedes"
#         },
#         ...
#       ]
#     }
#     """
#     try:
#         drivers = f1_service.get_available_drivers()
#         return {"drivers": drivers}
#     except ValueError as e:
#         raise HTTPException(status_code=400, detail=str(e))
#     except Exception as e:
#         raise HTTPException(status_code=500, detail=f"Error fetching drivers: {str(e)}")


# @router.post("/commentary/lap", response_model=CommentaryResponse)
# async def generate_commentary_from_lap(
#     driver: str,
#     lap_number: int,
#     sample_index: int = None,
#     commentary_style: str = "crofty",
#     context: str = None
# ):
#     """
#     Generate commentary from a specific lap of real F1 data
    
#     POST body:
#     {
#       "driver": "HAM",  // or driver number like "44"
#       "lap_number": 44,
#       "sample_index": 500,  // optional: specific moment in lap (if null, uses mid-lap)
#       "commentary_style": "crofty",
#       "context": "Fighting for position with Verstappen"
#     }
    
#     Returns: CommentaryResponse with generated commentary
#     """
#     try:
#         telemetry = f1_service.get_telemetry_for_lap(
#             driver_identifier=driver,
#             lap_number=lap_number,
#             sample_index=sample_index
#         )
        
#         # Build context with driver and lap info
#         full_context = f"Driver {driver}, Lap {lap_number}"
#         if context:
#             full_context += f". {context}"
        
#         # Generate commentary
#         commentary = commentary_service.generate_commentary(
#             telemetry=telemetry,
#             style=commentary_style,
#             context=full_context
#         )
        
#         return CommentaryResponse(
#             commentary=commentary,
#             timestamp=time.time(),
#             style=commentary_style
#         )
#     except ValueError as e:
#         raise HTTPException(status_code=400, detail=str(e))
#     except Exception as e:
#         raise HTTPException(status_code=500, detail=f"Error generating commentary: {str(e)}")
