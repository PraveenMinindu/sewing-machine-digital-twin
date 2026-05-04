from pydantic import BaseModel, Field
from datetime import datetime, timezone
from typing import Literal


class MachinePulse(BaseModel):
    """Raw pulse received from the simulator."""
    machine_id: str
    operation: str              # e.g. "stitch_complete", "cycle_end"
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class EnrichedPayload(BaseModel):
    """Fully enriched payload broadcast to Flutter dashboards."""
    machine_id: str
    operation: str
    timestamp: datetime

    # Efficiency layer
    units_produced: int
    efficiency_pct: float           # 0–100+
    target_rate_per_min: float      # Units/min needed to hit daily target

    # ML prediction layer
    projected_eod_units: float      # Predicted units by end of shift
    trend_slope: float              # Units/min rate of change (pos = improving)
    will_meet_target: bool

    # Flutter UI driver
    status: Literal["GREEN", "YELLOW", "RED"]