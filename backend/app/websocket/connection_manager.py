"""
Connection Manager
------------------
Maintains two separate sets of WebSocket connections:
  • machines  — simulator clients pushing pulses
  • dashboards — Flutter clients consuming enriched payloads
"""

import asyncio
import json
from fastapi import WebSocket
from typing import Literal


class ConnectionManager:
    def __init__(self) -> None:
        self.machines: set[WebSocket] = set()
        self.dashboards: set[WebSocket] = set()

    async def connect(
        self, websocket: WebSocket, role: Literal["machine", "dashboard"]
    ) -> None:
        await websocket.accept()
        if role == "machine":
            self.machines.add(websocket)
        else:
            self.dashboards.add(websocket)

    def disconnect(
        self, websocket: WebSocket, role: Literal["machine", "dashboard"]
    ) -> None:
        target = self.machines if role == "machine" else self.dashboards
        target.discard(websocket)

    async def broadcast_to_dashboards(self, payload: dict) -> None:
        """Fan-out enriched payload to all connected Flutter clients."""
        if not self.dashboards:
            return
        message = json.dumps(payload, default=str)
        dead: set[WebSocket] = set()
        results = await asyncio.gather(
            *[ws.send_text(message) for ws in self.dashboards],
            return_exceptions=True,
        )
        for ws, result in zip(self.dashboards, results):
            if isinstance(result, Exception):
                dead.add(ws)
        self.dashboards -= dead  # prune broken connections


# Singleton shared across the application
manager = ConnectionManager()