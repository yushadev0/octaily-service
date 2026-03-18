# Octaily API Service

![Delphi](https://img.shields.io/badge/Delphi-12.3-red.svg)
![Horse](https://img.shields.io/badge/Framework-Horse-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![Status](https://img.shields.io/badge/Status-Active-brightgreen.svg)

Octaily API is an ultra-lightweight, lightning-fast REST API server developed with Delphi and the Horse Framework. It serves as the backend engine for 8 different daily logic, word, and math puzzles.

Engineered with a smart Singleton Manager architecture, it operates as a headless, autonomous background service. It manages all game generators from a single center, automatically refreshing the puzzles every night at midnight. Built for pure stability, it runs continuously (24/7) in Windows Session 0 without memory leaks or GUI dependencies.

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

## Installation and Execution (Local Development)

Running the project on your local machine is straightforward. It requires no external dependencies (like Node.js, Python, etc.).

1. Clone the repository: `git clone https://github.com/yushadev0/octaily-service.git`
2. Open `OctailyService.dproj` in your Delphi IDE.
3. Ensure that the [Horse](https://github.com/HashLoad/horse) and [Horse.CORS](https://github.com/HashLoad/horse-cors) libraries are added to your Search Path.
4. Verify that your `data/` folder (containing dictionary .txt files) is in the same directory as your compiled `.exe`.
5. Compile and Run (F9). The server will start on port `9000` by default.

---

## Production Deployment (Windows Server)

Octaily is designed to run autonomously on Windows Server via Task Scheduler, requiring no active user session (Session 0 Isolation).

1. **Prepare the Directory:** Ensure that the `data/` folder (containing all your dictionary `.txt` files) is physically copied to the server and placed in the exact same directory as your compiled `OctailyService.exe`.
2. Open **Task Scheduler** and select **Create Task**.
3. **General:** Check `Run whether user is logged on or not` and `Run with highest privileges`.
4. **Triggers:** Add a new trigger -> `At startup`.
5. **Actions:** Select `Start a program`. Browse to your compiled `OctailyService.exe`. 
   * *Critical:* You must fill the `Start in (optional)` field with the folder path containing the `.exe` (e.g., `C:\Octaily\Server\`) to allow the engine to dynamically locate the `data/` folder.
6. **Firewall:** Open Windows Defender Firewall -> Inbound Rules -> New Rule -> Port -> Allow TCP Port `9000`.
7. **Logging:** The service will run invisibly and output all daily generation events, resets, and errors to an `OctailyServer.log` file in its root directory.

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

**Request:** `POST /api/guess/{game_name}`
**Body:** `Guess data (String or JSON Array)`

**Example:** `POST http://localhost:9000/api/guess/wordle_tr (Body: "KALEM")`
<br>**Response:**
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
### 3. Fetch Daily Answer 
Retrieves the exact daily solution for a specified game. To prevent cheating and unauthorized access, this endpoint dynamically verifies the user's status in the database. The API will only return the correct answer if the specified `user_id` has a completed game record for the current day. This works with `daily_scores` table. 

**Request:** `GET /api/fetch_answer/{game_name}/{user_id}`

**Example:** `GET http://localhost:9000/api/fetch_answer/wordle_tr/1`

**Response: (if user played the game)**
```json
{
  "success": true,
  "answer": "TORUL"
}
```

**Response: (if user not played the game)**
```json
{
  "success": false,
  "error": ""
}
```


---

## Architecture and Technologies
- **Language:** Pascal (Delphi 12.3)

- **Web Framework (Listener):** Horse (Ultra-lightweight middleware architecture, similar to Express.js)

- **Puzzle Patterns:** Factory Pattern (Generators), Singleton Pattern (Manager)

- **JSON Processing:** System.JSON Library

- **System Operations:** Headless Windows Service integration, thread-safe disk I/O logging, and dynamic runtime path resolution (ParamStr(0)).