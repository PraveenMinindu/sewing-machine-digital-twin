#  Real-Time Sewing Machine Digital Twin

## Tagline

An Industry 4.0 proof-of-concept that creates a live digital replica of a sewing machine,
calculates real-time production efficiency using industrial engineering standards, and predicts
end-of-day output using machine learning — all visible on a Flutter web dashboard.

---

## Problem Statement

Garment factories in Sri Lanka, including tier-one suppliers like MAS Holdings and Hirdaramani,
manage production lines of 40 to 200 sewing machines per floor. Today, most line supervisors
monitor machine performance using physical clipboards, manual counting, and end-of-shift reports.

This creates three critical problems:

1. Problems are discovered too late. A machine running at 60% efficiency for two hours
   goes unnoticed until the shift summary reveals a missed target.

2. Supervisors cannot be everywhere. One supervisor managing 50 machines cannot physically
   check each one frequently enough to catch performance drops in real time.

3. There is no prediction. Supervisors only know they missed the daily target after the shift
   ends — not three hours into the shift when corrective action is still possible.

These problems result in missed production targets, wasted capacity, and reactive rather than
proactive floor management.

---

## Solution Overview

Micro-Twin replaces the clipboard with a live digital dashboard. A Python simulator mimics
the electrical pulse a real PLC (Programmable Logic Controller) sends when a sewing machine
completes an operation. A FastAPI backend receives each pulse, calculates efficiency in real
time using Standard Minute Values, runs a linear regression model to predict end-of-day unit
counts, and broadcasts the enriched data over WebSocket to a Flutter web dashboard.

The dashboard changes background color based on efficiency status — green means on target,
yellow means at risk, red means action needed. A supervisor can see the machine status in
under three seconds without reading a single number.

---

## System Architecture

```
EDGE LAYER
  Python Simulator
  Mimics a sewing machine PLC
  Sends a JSON pulse every 20 to 40 seconds over WebSocket

        |
        | WebSocket /ws/machine
        |

BACKEND HUB (FastAPI)
  Pulse Ingestion       - validates incoming JSON, extracts machine_id and timestamp
  Efficiency Engine     - calculates efficiency % using SMV and elapsed shift time
  ML Predictor          - runs linear regression to project end-of-day unit count
  Connection Manager    - maintains WebSocket connections for machines and dashboards
  Broadcast             - pushes enriched payload to all connected Flutter clients

        |
        | WebSocket /ws/dashboard
        |

PRESENTATION LAYER (Flutter Web)
  Data Layer            - WebSocket datasource, JSON parsing, repository implementation
  Domain Layer          - pure business entities, repository contracts, use cases
  Presentation Layer    - BLoC state management, animated dashboard UI
```

Two WebSocket endpoints are used deliberately. The machine endpoint receives data in.
The dashboard endpoint pushes data out. Separating them keeps the routing logic clean
and allows multiple machines to push simultaneously while multiple dashboards receive
independently.

---

## Tech Stack

| Layer         | Technology        | Version   | Purpose                                      |
|---------------|-------------------|-----------|----------------------------------------------|
| Simulator     | Python            | 3.10+     | Sewing machine PLC emulation                 |
| Backend       | FastAPI           | 0.111.0   | WebSocket server and API hub                 |
| Backend       | Uvicorn           | 0.29.0    | ASGI server for FastAPI                      |
| Backend       | Pydantic          | 2.7.1     | Data validation and schema enforcement       |
| ML            | NumPy             | 1.26.4    | Linear regression via polyfit                |
| Transport     | WebSockets        | 12.0      | Real-time bidirectional communication        |
| Mobile / Web  | Flutter           | 3.x       | Cross-platform dashboard                     |
| Mobile / Web  | Dart              | 3.3+      | Flutter programming language                 |
| State         | flutter_bloc      | 8.1.5     | BLoC pattern state management                |
| DI            | get_it            | 7.7.0     | Dependency injection service locator         |
| Functional    | dartz             | 0.10.1    | Either type for error handling               |
| Equality      | equatable         | 2.0.5     | Value equality for Dart objects              |
| WebSocket     | web_socket_channel| 2.4.5     | Flutter WebSocket client                     |

---

## Features

Real-time efficiency calculation
  Every pulse from the simulator triggers an immediate efficiency calculation using
  the Standard Minute Value formula. The result is available in under 10 milliseconds.

Three-tier status system
  Efficiency above 85 percent displays GREEN status.
  Efficiency between 70 and 84 percent displays YELLOW status.
  Efficiency below 70 percent displays RED status.
  The Flutter dashboard background animates between these states smoothly.

Linear regression prediction
  After three data points are recorded, the ML predictor fits a trend line and projects
  the total units that will be produced by end of shift. The supervisor knows by 10am
  whether the 4pm target will be met.

Trend slope indicator
  The slope of the regression line shows whether production is accelerating or decelerating.
  A positive slope means the operator is finding their pace. A negative slope is an early
  warning sign that something is wrong.

Live pulse indicator
  A pulsing dot in the top right of the dashboard fires an animation on every new data
  point, giving the supervisor a visual heartbeat confirming the connection is alive.

Multi-machine architecture
  The backend uses dictionaries keyed by machine_id. Every new machine that connects is
  automatically tracked with its own independent efficiency engine and ML predictor.
  No code changes are required to add additional machines.

Auto-reconnect
  If the WebSocket connection drops, the Flutter datasource automatically attempts to
  reconnect after two seconds. The supervisor does not need to refresh the page.

---

## Sample Output

Backend terminal output after simulator connects:

```
[machine_LK_001] 1 units  |  50.0%  | RED
[machine_LK_001] 2 units  |  77.8%  | YELLOW
[machine_LK_001] 3 units  |  97.2%  | GREEN
[machine_LK_001] 4 units  | 110.8%  | GREEN
[machine_LK_001] 5 units  | 125.4%  | GREEN
```

WebSocket broadcast payload sample:

```json
{
  "machine_id": "machine_LK_001",
  "operation": "stitch_complete",
  "timestamp": "2024-01-15T09:32:11.000Z",
  "units_produced": 5,
  "efficiency_pct": 125.4,
  "target_rate_per_min": 0.97,
  "projected_eod_units": 1510.0,
  "trend_slope": 3.147,
  "will_meet_target": true,
  "status": "GREEN"
}
```

Dashboard display:
  - Background color: deep green
  - Status badge: ON TARGET
  - Efficiency ring: animated arc at 125%
  - Units produced card: 5 pcs
  - Trend card: +3.147 u/min
  - ML Projection card: 1510 projected vs 500 target
  - Progress bar: full green
  - Message: On track to meet daily target

---

## Project Structure

```
micro_twin/
|
|-- simulator/
|   |-- machine_simulator.py          Sewing machine pulse emitter
|
|-- backend/
|   |-- main.py                       FastAPI entry point and WebSocket router
|   |-- requirements.txt              Python dependencies
|   |
|   |-- app/
|       |-- __init__.py
|       |-- config.py                 SMV, daily target, efficiency thresholds
|       |-- models.py                 Pydantic schemas for pulse and payload
|       |
|       |-- core/
|       |   |-- __init__.py
|       |   |-- efficiency_engine.py  Real-time efficiency calculation
|       |   |-- ml_predictor.py       Linear regression end-of-day predictor
|       |
|       |-- websocket/
|           |-- __init__.py
|           |-- connection_manager.py WebSocket client registry and broadcaster
|           |-- handlers.py           Pulse ingestion and broadcast orchestration
|
|-- flutter_dashboard/
    |-- pubspec.yaml
    |-- lib/
        |-- main.dart
        |-- injection_container.dart   Dependency injection setup
        |
        |-- core/
        |   |-- error/
        |       |-- failure.dart       Typed failure classes
        |
        |-- features/
            |-- machine_monitor/
                |-- data/
                |   |-- datasources/
                |   |   |-- machine_ws_datasource.dart    WebSocket connection
                |   |-- models/
                |   |   |-- machine_pulse_model.dart      JSON parsing model
                |   |-- repositories/
                |       |-- machine_repository_impl.dart  Repository implementation
                |
                |-- domain/
                |   |-- entities/
                |   |   |-- machine_pulse.dart            Pure business entity
                |   |-- repositories/
                |   |   |-- machine_repository.dart       Repository contract
                |   |-- usecases/
                |       |-- watch_machine_stream.dart     Stream subscription use case
                |
                |-- presentation/
                    |-- bloc/
                    |   |-- machine_bloc.dart             Event to state logic
                    |   |-- machine_event.dart            Possible events
                    |   |-- machine_state.dart            Possible states
                    |-- pages/
                        |-- dashboard_page.dart           Full dashboard UI
```

---

## Installation and Setup

### Prerequisites

- Python 3.10 or higher
- Flutter 3.x with web support enabled
- Google Chrome browser
- Git

### Step 1 — Clone or download the project

```
Place the micro_twin folder on your Desktop
```

### Step 2 — Install backend dependencies

```bash
cd Desktop/micro_twin/backend
python -m pip install -r requirements.txt
```

### Step 3 — Install Flutter dependencies

```bash
cd Desktop/micro_twin/flutter_dashboard
flutter pub get
```

### Step 4 — Enable Flutter web

```bash
flutter config --enable-web
```

---

## Usage and How to Run

Three terminals must be open simultaneously. Start them in this order.

### Terminal 1 — Backend server

```bash
cd Desktop/micro_twin/backend
python -m uvicorn main:app --reload --port 8000
```

Expected output:
```
INFO: Uvicorn running on http://127.0.0.1:8000
INFO: Application startup complete.
```

### Terminal 2 — Machine simulator

```bash
cd Desktop/micro_twin/simulator
python machine_simulator.py
```

Expected output:
```
[SIM] Connected. Emitting pulses for machine_LK_001
[SIM] Sent → stitch_complete at 2024-01-15T09:32:11
```

To simulate multiple machines, open additional terminals and pass a machine ID:

```bash
python machine_simulator.py machine_LK_002
python machine_simulator.py machine_LK_003
```

### Terminal 3 — Flutter web dashboard

```bash
cd Desktop/micro_twin/flutter_dashboard
flutter run -d chrome
```

Chrome will open automatically. The dashboard will show a loading state until the
first pulse arrives from the simulator, then transition to live data display.

---

## How It Works (Workflow)

```
Step 1
  The simulator connects to ws://localhost:8000/ws/machine
  Every 20 to 40 seconds it sends a JSON pulse:
  { machine_id, operation, timestamp }

Step 2
  The FastAPI handler receives the pulse
  Pydantic validates the shape of the data
  The unit count for that machine increments by 1

Step 3
  The efficiency engine calculates:
  elapsed_minutes = (now - shift_start).total_seconds() / 60
  theoretical_units = elapsed_minutes / SMV
  efficiency_pct = (units_produced / theoretical_units) * 100
  status = GREEN if >= 85, YELLOW if >= 70, else RED

Step 4
  The ML predictor records the data point
  After 3 or more points it runs numpy.polyfit(times, units, degree=1)
  This returns slope and intercept of the best fit line
  projected_eod = slope * 480 + intercept
  will_meet_target = projected_eod >= 500

Step 5
  The connection manager broadcasts the enriched payload to all
  connected Flutter dashboard clients over ws://localhost:8000/ws/dashboard

Step 6
  The Flutter datasource receives the raw JSON text
  MachinePulseModel.fromJson() parses it into a typed Dart object
  The repository wraps it in Either<Failure, MachinePulse>
  The WatchMachineStream use case delivers it to the BLoC

Step 7
  The BLoC emits MachineUpdated state with the new pulse
  The dashboard rebuilds
  AnimatedContainer transitions background color
  Efficiency ring animates to new percentage
  All stat cards update with new values
```

---

## Model Evaluation and Metrics

The ML component uses Ordinary Least Squares linear regression via numpy.polyfit
with polynomial degree 1.

Key parameters:
  - Window size: last 30 data points (rolling window to adapt to pace changes)
  - Minimum samples: 3 data points before prediction is activated
  - Input features: elapsed shift minutes (X axis)
  - Target variable: cumulative units produced (Y axis)
  - Output: slope (units per minute), projected end-of-day units

Why linear regression was chosen:
  - Must run in real time on every pulse with zero perceptible latency
  - The relationship between time and cumulative units is fundamentally linear
    for a steady machine operator
  - No training data is required — the model fits live as data arrives
  - The slope output is directly interpretable by non-technical supervisors
  - Lightweight enough to run on a Raspberry Pi in an edge deployment

Limitations of the model:
  - Does not account for breaks, prayer times, or planned downtime
  - Does not incorporate operator skill history or fatigue curves
  - Assumes a linear production rate which breaks down during warm-up periods
  - Requires at least 3 pulses before producing a prediction

---

## Limitations

1. In-memory state only
   All machine data resets when the backend restarts. There is no database.
   Historical shift data is not persisted between sessions.

2. Simulated PLC only
   The simulator is a Python script. Real deployment requires hardware integration
   with industrial protocols such as Modbus TCP, OPC-UA, or MQTT.

3. Single machine dashboard
   The Flutter UI currently displays the most recently updated machine only.
   A production system requires a floor view showing all machines simultaneously.

4. Cold start inaccuracy
   Efficiency readings in the first 2 to 3 minutes of a shift are unreliable
   because the elapsed time denominator is too small. A pre-shift warmup offset
   is applied in the current implementation to mitigate this.

5. No authentication
   Any client that knows the WebSocket URL can connect and receive production data.
   A production system requires token-based authentication on all endpoints.

6. No alerting system
   When a machine drops to RED status, the dashboard shows the color change but
   sends no push notification or alarm to the supervisor.

---

## Future Improvements

Phase 2 — Multi-machine floor view
  A grid dashboard showing all machines simultaneously. Color-coded cards for
  each machine. Red machines surfaced to the top as priority alerts. Supervisor
  taps any card to drill into the machine detail view.

Phase 3 — Persistent time-series storage
  Replace in-memory dictionaries with InfluxDB or TimescaleDB. Store every pulse
  permanently. Enable shift-over-shift comparison and weekly trend analysis.

Phase 4 — Real hardware integration
  Replace the Python simulator with an OPC-UA or Modbus TCP adapter that reads
  signals directly from the PLC attached to the physical sewing machine. Target
  compatibility with Juki, Brother, and Pegasus industrial machines.

Phase 5 — Enhanced ML model
  Incorporate operator skill grade, fabric type, operation complexity, and time
  of day as additional features. Move from linear regression to a gradient boosted
  model trained on historical shift data. Predict not just end-of-day count but
  also the probability of hitting the target.

Phase 6 — Push notifications
  Integrate Firebase Cloud Messaging to send a push notification to the supervisor's
  phone when any machine drops to RED status for more than 5 consecutive minutes.

Phase 7 — Supervisor action logging
  When a supervisor taps a RED machine and visits it on the floor, they log the
  reason in the app. This creates a labeled dataset of machine problems and their
  causes, which feeds back into improving the ML model over time.

Phase 8 — Line balancing view
  Show the bottleneck operation on the production line — the one machine whose
  slowness is limiting the output of all machines downstream. This is the highest
  value insight for an Industrial Engineer.

---

## Contributing

This project was built as a proof-of-concept for an internship portfolio targeting
Industrial IoT roles in the Sri Lankan apparel manufacturing sector.

If you want to extend this project, the recommended contribution areas are:

  Backend        → add a time-series database layer under app/storage/
  Flutter        → build the multi-machine floor view screen
  ML             → improve the predictor with additional features
  Hardware       → write an OPC-UA adapter to replace the simulator
  Testing        → add unit tests for efficiency_engine.py and ml_predictor.py

To contribute, fork the repository, create a feature branch, and open a pull request
with a clear description of what was changed and why.

---

## Project Context

Built as a 3-week proof-of-concept to demonstrate Industry 4.0 capabilities for
internship applications at tier-one Sri Lankan apparel manufacturers.

The system demonstrates:
  - Real-time IoT data pipeline using WebSocket
  - Industrial engineering concepts (SMV, efficiency, daily targets)
  - Machine learning applied to live production data
  - Clean Architecture in a Flutter mobile application
  - End-to-end thinking from hardware signal to mobile dashboard

Target industry: Apparel manufacturing, specifically operations at companies operating
under the WRAP, LEED, and SA8000 certification frameworks where production data
integrity and real-time monitoring are operational requirements.
