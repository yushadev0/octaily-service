# Octaily API Service

![Delphi](https://img.shields.io/badge/Delphi-10.4+-red.svg)
![Horse](https://img.shields.io/badge/Framework-Horse-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![Status](https://img.shields.io/badge/Status-Active-brightgreen.svg)

Octaily API is an ultra-lightweight, lightning-fast REST API server developed with Delphi and the Horse Framework. It hosts 8 different daily logic, word, and math puzzles.

Powered by a smart Singleton Manager architecture running in the background, it manages all game engines from a single center and automatically refreshes the puzzles every night at midnight. It is designed to run continuously for days without memory leaks.

---

## Supported Game Engines (Generators)

The system currently supports 8 different "Daily Puzzle" engines:

* **Wordle (TR & EN):** Classic 5-letter word guessing game powered by a custom dictionary algorithm.
* **Queens:** Zone control and logical placement on a chessboard.
* **Nerdle:** Mathematical equation puzzle engine.
* **Zip:** Hamiltonian path and maze solving algorithm.
* **Hexle:** Color codes (HEX) and proximity/temperature analysis.
* **Worldle:** Geographical distance and direction finding using the Haversine formula.
* **Sudoku:** Real-time 9x9 grid generation and validation using a Backtracking algorithm.

---

## Installation and Execution

Running the project on your local machine or server is straightforward. It requires no external dependencies (like Node.js, Python, etc.).

1. Clone the repository: `git clone https://github.com/yourusername/octaily-api.git`
2. Open `OctailyAPI.dpr` (or the project file containing `Unit1.pas`) in your Delphi IDE.
3. Ensure that the [Horse](https://github.com/HashLoad/horse) and [Horse.CORS](https://github.com/HashLoad/horse-cors) libraries are added to your Search Path.
4. Compile the project (F9). The server will start on port `9000` by default.

---

## API Endpoints (Usage Guide)

All requests support CORS and can be consumed directly by Frontend applications (Vue.js, React, UniGUI, vanilla HTML/JS, etc.).

### 1. Get Daily Puzzle
Fetches the initial data (Grid, target info, etc.) of the specified game for the current day.

**Request:** `GET /api/game/{game_name}`
**Example:** `GET http://localhost:9000/api/game/sudoku`

**Response:**
```json
{
  "success": true,
  "game": "sudoku",
  "grid": [
    [2,0,1,0,0,6,0,4,0],
    [3,0,5,1,7,0,0,6,0],
    [6,0,9,2,0,0,1,3,0],
    [0,0,3,0,0,0,0,0,9],
    [4,5,0,0,9,0,0,0,6],
    [0,0,0,0,2,0,4,0,1],
    [0,0,0,0,3,7,0,9,4],
    [0,0,4,9,8,0,5,0,0],
    [0,0,0,0,1,4,6,7,2]
  ]
}
```

### 2. Submit and Check Guess
Sends the user's guess to the game engine and returns the calculated result (distance, colors, accuracy, etc.).

**Request:** `GET /api/game/{game_name}`
**Body:** `Guess data (String or JSON Array)`

**Example:** `POST http://localhost:9000/api/guess/wordle_tr (Body: "KALEM")`

**Response:**
```json
{
  "success": true,
  "game": "wordle_tr",
  "guess": "KALEM",
  "result": [
    {"letter": "K", "status": "present"},
    {"letter": "A", "status": "absent"},
    {"letter": "L", "status": "absent"},
    {"letter": "E", "status": "present"},
    {"letter": "M", "status": "absent"}
  ]
}
```
---
## Architecture and Technologies
- **Language:** Pascal (Delphi 12.3)

- **Web Framework (Listener):** Horse (Ultra-lightweight middleware architecture, similar to Express.js)

- **Puzzle Patterns:** Factory Pattern (Generators), Singleton Pattern (Manager)

- **JSON Processing:** System.JSON