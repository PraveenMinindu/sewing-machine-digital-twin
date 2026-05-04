"""
ML Predictor — Lightweight Linear Regression
---------------------------------------------
Uses only numpy (no sklearn) to stay minimal and run in real-time.

Model:
  X = elapsed minutes at each recorded pulse
  y = cumulative units produced at that time

  We fit y = slope * X + intercept using ordinary least squares.
  Then project: projected_eod = slope * SHIFT_MINUTES + intercept

The slope (units/min) is the key insight for operators:
  • slope > target_rate_per_min  → on track or ahead
  • slope < target_rate_per_min  → falling behind
"""

import numpy as np
from collections import deque
from datetime import datetime, timezone
from app.config import SHIFT_MINUTES, DAILY_TARGET, ML_MIN_SAMPLES


class LinearPredictor:
    def __init__(self, window_size: int = 30) -> None:
        # Rolling window: avoid unbounded memory on long shifts
        self._times: deque[float] = deque(maxlen=window_size)
        self._units: deque[int] = deque(maxlen=window_size)
        self._shift_start: datetime | None = None

    def record(self, units_produced: int, now: datetime) -> None:
        if self._shift_start is None:
            self._shift_start = now
        elapsed = (now - self._shift_start).total_seconds() / 60
        self._times.append(elapsed)
        self._units.append(units_produced)

    def predict(self, now: datetime) -> dict:
        """Returns slope, projected EOD units, and target-met flag."""
        n = len(self._times)

        if n < ML_MIN_SAMPLES or self._shift_start is None:
            # Not enough data yet — return safe defaults
            return {
                "trend_slope": 0.0,
                "projected_eod_units": 0.0,
                "will_meet_target": False,
            }

        X = np.array(self._times, dtype=float)
        y = np.array(self._units, dtype=float)

        # Ordinary Least Squares: β = (XᵀX)⁻¹ Xᵀy
        # Using np.polyfit(degree=1) — same math, cleaner API
        slope, intercept = np.polyfit(X, y, 1)

        # Clamp slope: production can't be negative
        slope = max(slope, 0.0)

        # Project to end-of-shift
        projected_eod = slope * SHIFT_MINUTES + intercept
        projected_eod = max(projected_eod, 0.0)

        return {
            "trend_slope": round(float(slope), 4),       # units per minute
            "projected_eod_units": round(projected_eod, 1),
            "will_meet_target": projected_eod >= DAILY_TARGET,
        }

    def reset(self) -> None:
        """Call at the start of each shift."""
        self._times.clear()
        self._units.clear()
        self._shift_start = None