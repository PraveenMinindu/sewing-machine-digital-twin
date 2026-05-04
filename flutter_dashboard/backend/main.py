from fastapi import FastAPI, WebSocket
from app.websocket.handlers import (
    handle_machine_connection,
    handle_dashboard_connection,
)
from app.config import WS_MACHINE_PATH, WS_DASHBOARD_PATH

app = FastAPI(title="Micro-Twin Hub", version="0.1.0")


@app.get("/health")
async def health() -> dict:
    return {"status": "ok"}


@app.websocket(WS_MACHINE_PATH)
async def machine_ws(websocket: WebSocket):
    """Simulator connects here and pushes pulses."""
    await handle_machine_connection(websocket)


@app.websocket(WS_DASHBOARD_PATH)
async def dashboard_ws(websocket: WebSocket):
    """Flutter clients connect here and receive enriched payloads."""
    await handle_dashboard_connection(websocket)