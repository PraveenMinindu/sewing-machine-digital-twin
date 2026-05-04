"""
Sewing Machine Simulator
------------------------
Sends a JSON pulse over WebSocket every 10–30 seconds,
mimicking the interrupt a real PLC would fire on cycle completion.

Run: python machine_simulator.py
"""

import asyncio
import json
import random
from datetime import datetime, timezone, timezone
import websockets
import sys

WS_URL = "ws://localhost:8000/ws/machine"

MACHINE_ID = sys.argv[1] if len(sys.argv) > 1 else "machine_LK_001"
OPERATIONS = ["stitch_complete", "cycle_end", "seam_closed", "bartack_done"]


async def run_simulator() -> None:
    print(f"[SIM] Connecting to {WS_URL} …")
    async with websockets.connect(WS_URL) as ws:
        print(f"[SIM] Connected. Emitting pulses for {MACHINE_ID}")
        while True:
            interval = random.uniform(10, 30)
            await asyncio.sleep(interval)

            pulse = {
                "machine_id": MACHINE_ID,
                "operation": random.choice(OPERATIONS),
                "timestamp": datetime.now(timezone.utc).isoformat(),
            }
            await ws.send(json.dumps(pulse))
            print(f"[SIM] Sent → {pulse['operation']} at {pulse['timestamp']}")


if __name__ == "__main__":
    asyncio.run(run_simulator())