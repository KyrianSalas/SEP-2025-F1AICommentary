from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any

class CommentaryMoment(BaseModel):
    timestamp: float = Field(..., description="Time in seconds when this commentary should play")
    text: str = Field(..., description="The commentary text")
    context: Optional[str] = Field(None, description="Optional context about what's happening")
    priority: int = Field(..., ge=1, le=3, description="Priority level (1=high, 2=medium, 3=low)")


class RaceMetadata(BaseModel):
    venue: str = Field(default="Unknown Track", description="Track/venue name")
    vehicle: str = Field(default="Unknown Vehicle", description="Vehicle/car name")
    date: Optional[str] = Field(None, description="Session date")
    time: Optional[str] = Field(None, description="Session time")
    duration: Optional[float] = Field(None, description="Total session duration in seconds")
    total_laps: Optional[int] = Field(None, description="Total number of laps")

class PreGeneratedCommentary(BaseModel):
    metadata: RaceMetadata = Field(..., description="Race/session metadata")
    commentator_style: str = Field(..., description="Commentator style used")
    moments: List[CommentaryMoment] = Field(..., description="All commentary moments sorted by timestamp")
    generation_timestamp: float = Field(..., description="When this commentary was generated")
    model_used: Optional[str] = Field(None, description="OpenAI model used for generation")
    
    def get_moments_at_time(self, start_time: float, end_time: float, min_priority: int = 3) -> List[CommentaryMoment]:
        return [
            moment for moment in self.moments 
            if start_time <= moment.timestamp <= end_time and moment.priority <= min_priority
        ]
    
    def get_next_moment(self, current_time: float, min_priority: int = 3) -> Optional[CommentaryMoment]:
        upcoming = [m for m in self.moments if m.timestamp > current_time and m.priority <= min_priority]
        return upcoming[0] if upcoming else None


class CommentaryGenerationRequest(BaseModel):
    csv_filename: str = Field(..., description="Name of the CSV file to process")
    commentator_style: str = Field(default="crofty", description="Commentator style to use")
    target_moment_count: int = Field(default=50, ge=10, le=200, description="Target number of commentary moments")
    priority_distribution: Optional[Dict[int, float]] = Field(
        default={"1": 0.3, "2": 0.4, "3": 0.3},
        description="Distribution of priorities NEEDS TO SUM TO 1"
    )