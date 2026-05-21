# theGhost

theGhost is a mobile-first network discovery and device scanner app. The Flutter client scans local Wi‑Fi networks and devices, while a small Node.js backend stores scan results in a MySQL database for history and analysis.

## Technical Description

- **Mobile app (Flutter)**: Located in the `app/` folder. Uses `wifi_scan`, `network_info_plus`, `dart_ping`, and `http` to discover Wi‑Fi networks, probe devices on the LAN, and report results to the backend.
- **Backend (Node.js / Express)**: Located in the `backend/` folder. Provides a REST API to receive and serve scan sessions and discovered devices. Uses `mysql2` to connect to a MySQL database.
- **Database (MySQL)**: Schema is provided at `database/schema.sql`. Tables: `wifi_networks`, `scan_sessions`, `network_devices`, `camera_devices`.

## Features

- Scan nearby Wi‑Fi networks (SSID, BSSID, signal strength, encryption, frequency)
- Perform basic device discovery on the connected network (IP, MAC, open ports)
- Detect likely camera devices and store findings
- Persist scan sessions and history to a MySQL database

## Repo Layout

- `app/` — Flutter mobile application
- `backend/` — Node.js API server
- `database/schema.sql` — SQL schema for MySQL

## Prerequisites

- Flutter SDK (see https://flutter.dev/docs/get-started/install)
- Android Studio / Xcode / platform toolchains for your target
- Node.js (v16+ recommended) and npm
- MySQL server (local or remote) or Docker

## Backend: Setup & Run

1. Create a `.env` file in the `backend/` folder with DB credentials (example):

```
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=root
DB_PASSWORD=yourpassword
DB_NAME=theghost
```

2. Install dependencies and start the server:

```bash
cd backend
npm install
npm run start
```

3. Development mode (auto-reload):

```bash
npm run dev
```

The backend listens on the port configured in `src/app.js` (check `backend/src/app.js`).

## Database: Setup (MySQL)

Option A — Use an existing MySQL server:

```bash
# create the database and apply schema (example using mysql client)
mysql -u root -p < database/schema.sql
```

Option B — Quick start with Docker:

```bash
# start a MySQL container
docker run --name theghost-mysql -e MYSQL_ROOT_PASSWORD=yourpassword -e MYSQL_DATABASE=theghost -p 3306:3306 -d mysql:8
# apply schema from the project
docker exec -i theghost-mysql mysql -u root -pyourpassword theghost < database/schema.sql
```

After the database is ready, ensure `backend/.env` points at the database and start the backend.

## Flutter App: Setup & Run

1. From the `app/` folder install packages and run:

```bash
cd app
flutter pub get
flutter run
```

2. Permissions: The app requires location and network permissions on Android to perform Wi‑Fi scans. Ensure you grant location permission at runtime. The `permission_handler` package is used in the app.

3. Configure the backend endpoint: If the app posts scan results to the backend, locate the API base URL in the app source (search for `http` calls in `app/lib/services` or `app/lib`) and update it to point to your backend host (e.g., `http://192.168.1.50:3000`).

## Notes & Troubleshooting

- The database schema expects MySQL (uses `AUTO_INCREMENT` and `CREATE DATABASE`).
- Backend uses `mysql2` and loads credentials from environment variables via `dotenv`.
- If running the backend and app on different machines, ensure the backend host is reachable from the mobile device and CORS is allowed (backend already includes `cors` dependency).

## Contributing

Feel free to open issues or pull requests. If you want help getting started, ask for a small issue to be assigned.

