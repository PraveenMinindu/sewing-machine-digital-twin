"""
WebSocket Handlers
------------------
Stitches together:
  Pulse arrival → Efficiency Engine → ML Predictor → Broadcast
"""

import json
from datetime import datetime, timezone, timedelta
from fastapi import WebSocket, WebSocketDisconnect

from app.models import MachinePulse, EnrichedPayload
from app.core.efficiency_engine import EfficiencyEngine
from app.core.ml_predictor import LinearPredictor
from app.websocket.connection_manager import manager

# One engine + predictor per machine_id
# In a real system, push this to Redis; for PoC, in-memory is fine.
_engines: dict[str, EfficiencyEngine] = {}
_predictors: dict[str, LinearPredictor] = {}
_units_count: dict[str, int] = {}
_shift_starts: dict[str, datetime] = {}


def _get_or_create(machine_id: str):
    if machine_id not in _engines:
        _engines[machine_id] = EfficiencyEngine()
        _predictors[machine_id] = LinearPredictor()
        _units_count[machine_id] = 0
        _shift_starts[machine_id] = datetime.now(timezone.utc) - timedelta(minutes=1)
    return (
        _engines[machine_id],
        _predictors[machine_id],
    )


async def handle_machine_connection(websocket: WebSocket) -> None:
    await manager.connect(websocket, role="machine")
    try:
        while True:
            raw = await websocket.receive_text()
            await _process_pulse(raw)
    except WebSocketDisconnect:
        manager.disconnect(websocket, role="machine")


async def handle_dashboard_connection(websocket: WebSocket) -> None:
    await manager.connect(websocket, role="dashboard")
    try:
        # Keep alive — dashboards only receive, never send
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(websocket, role="dashboard")


async def _process_pulse(raw: str) -> None:
    try:
        data = json.loads(raw)
        pulse = MachinePulse(**data)
    except Exception as e:
        print(f"[WARN] Malformed pulse: {e}")
        return

    mid = pulse.machine_id
    now = pulse.timestamp
    engine, predictor = _get_or_create(mid)

    # Each pulse = one completed unit (adjust multiplier for your op type)
    _units_count[mid] += 1
    units = _units_count[mid]

    # --- Efficiency ---
    eff = engine.calculate(
        units_produced=units,
        shift_start=_shift_starts[mid],
        now=now,
    )

    # --- ML Prediction ---
    predictor.record(units_produced=units, now=now)
    pred = predictor.predict(now=now)

    # --- Assemble & Broadcast ---
    payload = EnrichedPayload(
        machine_id=mid,
        operation=pulse.operation,
        timestamp=now,
        units_produced=units,
        target_rate_per_min=eff["target_rate_per_min"],
        efficiency_pct=eff["efficiency_pct"],
        projected_eod_units=pred["projected_eod_units"],
        trend_slope=pred["trend_slope"],
        will_meet_target=pred["will_meet_target"],
        status=eff["status"],
    )

    await manager.broadcast_to_dashboards(payload.model_dump())
    print(f"[{mid}] {units} units | {eff['efficiency_pct']:.1f}% | {eff['status']}")