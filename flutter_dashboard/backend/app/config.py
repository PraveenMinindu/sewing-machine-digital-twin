# Central configuration — all magic numbers live here.
# Change SMV or targets in one place, the whole system adapts.

SMV: float = 0.5            # Standard Minute Value per unit (minutes)
DAILY_TARGET: int = 500     # Units required by end of shift
SHIFT_HOURS: int = 8        # Total shift duration in hours
SHIFT_MINUTES: int = SHIFT_HOURS * 60

# Efficiency thresholds that drive Flutter background color
EFFICIENCY_GREEN_THRESHOLD: float = 85.0   # ≥ this → GREEN
EFFICIENCY_YELLOW_THRESHOLD: float = 70.0  # ≥ this → YELLOW, else RED

# Minimum data points before the linear predictor is trusted
ML_MIN_SAMPLES: int = 3

# WebSocket endpoint paths
WS_MACHINE_PATH: str = "/ws/machine"    # Simulator connects here
WS_DASHBOARD_PATH: str = "/ws/dashboard" # Flutter connects here