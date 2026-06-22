# Stack: Go (HTTP backend)

This fragment is composed into the `init-project` subagent prompt when the user selects Go as the backend stack.

## Directories

Create:

```
backend/cmd/server/
backend/admin/
backend/migrations/
backend/secrets/
```

## .gitignore additions

Append to `.gitignore`:

```
/tmp/
vendor/
```

## Files

### `backend/go.mod`

Replace `<project-name>` with lowercased project name.

```
module github.com/<org>/<project-name>

go 1.22
```

(`<org>` defaults to the project name if no organisation is provided.)

### `backend/cmd/server/main.go`

```go
package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
)

func main() {
	mux := http.NewServeMux()

	mux.HandleFunc("GET /health", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, map[string]string{"status": "ok"})
	})

	mux.HandleFunc("GET /", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, map[string]string{"status": "running"})
	})

	port := os.Getenv("APP_PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("listening on :%s", port)
	if err := http.ListenAndServe(":"+port, mux); err != nil {
		log.Fatal(err)
	}
}

func writeJSON(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(v)
}
```

### `backend/.air.toml`

Standard `air` live-reload config pointing at `cmd/server/`.

### `backend/Dockerfile`

Multi-stage Dockerfile: `dev` target runs `air`, `prod` target builds a static binary.

### `backend/.env.example`

Keys: `APP_ENV`, `APP_PORT`, `APP_SECRET_KEY`, `DATABASE_URL`, `REDIS_URL`. If a domain is set: also `APP_DOMAIN`. If no domain: `APP_DOMAIN=localhost`.

### `backend/.env`

```
# DO NOT COMMIT — copy .env.example and fill values
```

### `backend/secrets/.gitkeep`

Empty file.

### Docker compose files

Docker Compose scaffolding is now handled by the modular scripts (same as the Python stack):

- `scripts/modules/docker.sh` — writes `backend/docker-compose.yml` and `backend/docker-compose.prod.yml`
- `scripts/modules/postgres.sh` — adds Postgres service into the compose files
- `scripts/modules/redis.sh` — adds Redis service into the compose files

These scripts are invoked by `init-project` when the user opts into the backend-infra module. This reference fragment does not need to call them directly.
