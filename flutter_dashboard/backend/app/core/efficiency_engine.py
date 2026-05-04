"""
Efficiency Engine
-----------------
Converts raw pulse counts into meaningful production metrics.

Formula:
  Theoretical capacity = SHIFT_MINUTES / SMV
  Efficiency %         = (units_produced / theoretical_capacity) × 100

  Target rate          = remaining_units / remaining_minutes
"""

from datetime import datetime, timezone
from app.config import SMV, DAILY_TARGET, SHIFT_MINUTES
from app.config import EFFICIENCY_GREEN_THRESHOLD, EFFICIENCY_YELLOW_THRESHOLD


class EfficiencyEngine:
    def __init__(self) -> None:
        self._theoretical_capacity = SHIFT_MINUTES / SMV  # = 960 units max

    def calculate(
        self,
        units_produced: int,
        shift_start: datetime,
        now: datetime,
    ) -> dict:
        elapsed_minutes = (now - shift_start).total_seconds() / 60
        elapsed_minutes = max(elapsed_minutes, 0.001)  # avoid div-by-zero

        # Actual rate vs what the machine *could* theoretically produce
        # in the elapsed time at perfect efficiency
        theoretical_so_far = elapsed_minutes / SMV
        efficiency_pct = (units_produced / theoretical_so_far) * 100

        # How fast do we need to go from now to hit 500?
        remaining_units = max(DAILY_TARGET - units_produced, 0)
        remaining_minutes = max(SHIFT_MINUTES - elapsed_minutes, 0.001)
        target_rate_per_min = remaining_units / remaining_minutes

        status = self._derive_status(efficiency_pct)

        return {
            "efficiency_pct": round(efficiency_pct, 2),
            "target_rate_per_min": round(target_rate_per_min, 4),
            "status": status,
        }

    @staticmethod
    def _derive_status(efficiency_pct: float) -> str:
        if efficiency_pct >= EFFICIENCY_GREEN_THRESHOLD:
            return "GREEN"
        elif efficiency_pct >= EFFICIENCY_YELLOW_THRESHOLD:
            return "YELLOW"
        return "RED"