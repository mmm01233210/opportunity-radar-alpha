# Opportunity Radar — Alpha

A working **local alpha** of the AI-native reality-synthesis platform.
Demonstrates the platform's full flow on synthetic ICT data, end-to-end:

> Source registry → Synthetic signals → Layer + theme classification → Entity tagging → Noise (N1–N6) → Reinforcement (decomposed) → Clustering → Interpretation with evidence → Search → Review queue → Append-only audit log.

> ⚠ **Alpha mode.** Synthetic ICT data only. Placeholder intelligence logic. Not production. Not connected to real sources. Not a worth-building system.

---

## What this is

The platform's six-level output ladder is implemented end-to-end, but every "intelligence" module is a clearly-marked placeholder so that real implementations (per the Stage 2 work orders) can be swapped in without rewriting the surrounding system. See [docs/PLACEHOLDER_LOGIC.md](docs/PLACEHOLDER_LOGIC.md).

The platform's identity disciplines are preserved even at this alpha stage:

- **Decomposed confidence** — never a single overall score
- **Decomposed reinforcement** — score shown only alongside layer coverage, independent sources, saturation
- **Mandatory contradiction surfacing** — visible by default, never collapsed
- **Evidence-grounded interpretation** — every assertion carries `evidence_signal_ids`
- **No worth-building, no calibration, no concept generation, no recommendations**
- **Append-only audit chain** — sha256-linked, with database rules denying UPDATE/DELETE

For the full list of explicit boundaries, see [docs/ALPHA_BOUNDARY.md](docs/ALPHA_BOUNDARY.md).

---

## Architecture (one screen)

```
┌────────────────────────────────────────────────────────────────┐
│  Browser  ─  http://localhost:3000                             │
│  Next.js 14 App Router  +  Tailwind  +  TypeScript             │
└──────────────────────────────┬─────────────────────────────────┘
                               │ JSON / fetch
┌──────────────────────────────▼─────────────────────────────────┐
│  Backend  ─  http://localhost:8000  (FastAPI / Python 3.11)    │
│                                                                │
│  Routes:  /health  /sources  /entities  /signals  /clusters    │
│           /interpretations  /search  /review  /audit           │
│                                                                │
│  Modules: classify · noise · reinforce · cluster · interpret   │
│           embed · audit · pipeline                             │
└──────────────────────────────┬─────────────────────────────────┘
                               │ asyncpg
┌──────────────────────────────▼─────────────────────────────────┐
│  PostgreSQL 16 + pgvector (docker-compose)                     │
│  Append-only audit_log enforced via DB rules                   │
└────────────────────────────────────────────────────────────────┘
```

For the data model, see [docs/DATA_MODEL.md](docs/DATA_MODEL.md).

---

## Prerequisites

| Tool | Minimum | Notes |
|---|---|---|
| Docker (with Compose) | 24+ | runs Postgres locally |
| Python | 3.11 | backend |
| Node.js | 20+ | frontend |
| npm | 10+ | bundled with Node |
| make | any | thin orchestration of commands |

The first run will download the sentence-transformers model (`all-MiniLM-L6-v2`, ~80 MB) into your local huggingface cache. After that, the alpha runs offline.

---

## Quick start

```bash
# 1. Configure environment
cp .env.example .env

# 2. Start Postgres (docker-compose)
make up

# 3. Install backend dependencies (one-time)
make install-backend

# 4. Run migrations
make migrate

# 5. Load seed data (12 sources, 30 entities, 60 signals)
make seed

# 6. Run the processing pipeline
#    (embeddings, classification, noise, clustering, interpretation, audit)
make process-all

# 7. Install frontend dependencies (one-time)
make install-frontend

# 8. Run the backend (terminal 1)
make dev-backend

# 9. Run the frontend (terminal 2)
make dev-frontend

# 10. Open the app
open http://localhost:3000
```

### Alternative: bare-metal Postgres (no Docker)

If you cannot run Docker, install PostgreSQL 16 + the `pgvector` extension
locally (e.g. `apt install postgresql-16 postgresql-16-pgvector` on Debian/Ubuntu),
then set up the alpha database before running migrations. **`CREATE EXTENSION
vector` requires superuser, so it must be run as the `postgres` role:**

```bash
sudo -u postgres psql -c "CREATE USER alpha WITH PASSWORD 'alpha_local_only';"
sudo -u postgres psql -c "CREATE DATABASE opportunity_radar_alpha OWNER alpha;"
sudo -u postgres psql -d opportunity_radar_alpha -c "CREATE EXTENSION vector;"
# Then proceed with `make migrate`, `make seed`, etc.
```

(The Docker Compose path uses the `pgvector/pgvector:pg16` image, which
runs the extension setup automatically.)

For a full reset of the local database:

```bash
make reset
```

---

## Make targets

```
make up                  start postgres
make down                stop postgres
make install-backend     create venv and install backend deps
make install-frontend    npm install
make migrate             run alembic migrations
make seed                load synthetic seed data
make process-all         run the full processing pipeline
make dev-backend         start FastAPI (port 8000)
make dev-frontend        start Next.js (port 3000)
make verify-audit        verify audit-chain integrity from CLI
make test-backend        run backend tests
make psql                open psql against local db
make logs                tail postgres logs
make reset               down + up + migrate + seed + process-all
make clean               down -v (DESTRUCTIVE: drops volume)
```

---

## What you should see

After `make process-all`, the dashboard should report approximately:

- **60 signals** across 4 layers (mega / macro / meso / micro)
- **12 sources** with 6-component credibility
- **≥ 4 clusters** including:
  - `cluster-ai-inference-cost` — touches all 4 layers (Pattern A reinforcement)
  - `cluster-edge-regulatory-divergence` — contains a **seeded contradiction** between two regulator signals (Regulator Beta requires data residency vs Regulator Alpha permits cross-border)
- **≥ 1 open review item** auto-created for the contradiction cluster
- **~70+ audit events** in a verifiable hash chain

Walk through:

1. **Dashboard** → see the counts and layer distribution.
2. **Signals** → filter to `layer=macro` then `theme=regulation`. Click `sig-007` or `sig-008` (the two contradicting regulator signals).
3. **Clusters** → open `cluster-edge-regulatory-divergence`. The contradiction panel is visible by default with both signals linked.
4. **Interpretation** → click "View interpretation". Each assertion shows `evidence_signal_ids` as clickable links.
5. **Search** → query `GPU inference cost` in semantic mode. The AI inference cost cluster ranks high.
6. **Review** → resolve the contradiction item. Refresh /audit. The new event has appeared and the chain still verifies.
7. **Audit** → click "Verify chain integrity". `✓ Chain verified · total events: N`.

---

## Project layout

```
opportunity-radar-alpha/
├── docker-compose.yml             # Postgres 16 + pgvector
├── Makefile                       # all run targets
├── .env.example                   # config template
│
├── backend/                       # FastAPI / Python 3.11
│   ├── pyproject.toml
│   ├── alembic/                   # migrations (001_initial)
│   ├── app/
│   │   ├── main.py                # boundary check + route mounting
│   │   ├── config.py              # alpha boundary flags
│   │   ├── db.py                  # asyncpg pool
│   │   ├── models/schemas.py
│   │   ├── modules/               # placeholder intelligence
│   │   │   ├── classify.py
│   │   │   ├── noise.py
│   │   │   ├── reinforce.py
│   │   │   ├── cluster.py
│   │   │   ├── interpret.py
│   │   │   ├── embed.py
│   │   │   ├── audit.py
│   │   │   └── pipeline.py
│   │   ├── routes/                # FastAPI route modules (9)
│   │   ├── scripts/               # process_all, verify_audit
│   │   └── seed/                  # sources/entities/signals JSON + loader
│   └── tests/                     # 33 passing tests
│
├── frontend/                      # Next.js 14 + Tailwind + TS
│   ├── package.json
│   ├── tsconfig.json
│   └── src/
│       ├── app/                   # 10 pages including [id] dynamic routes
│       ├── components/            # 16 components incl. ContradictionPanel
│       └── lib/                   # api · types · format · constants
│
└── docs/
    ├── ALPHA_BOUNDARY.md          # what alpha does NOT do
    ├── PLACEHOLDER_LOGIC.md       # how to swap to real Stage 2 logic
    └── DATA_MODEL.md              # schema reference
```

---

## Boundary controls (enforced in code, not just policy)

The backend refuses to start if any of these flags is `true`:

```
ALLOW_EXTERNAL_HTTP
ALLOW_PAID_SOURCES
ALLOW_AI_PIPELINE_PROD
ALLOW_WORTH_BUILDING
ALLOW_CALIBRATION_SERVICE
ALLOW_CONCEPT_GENERATION
ALLOW_PRODUCTION_TRAFFIC
```

`audit_log` table has database-level rules denying UPDATE and DELETE — even
if application code tried to mutate, Postgres silently refuses. The
hash chain detects any tampering.

The Alpha Mode banner is sticky and non-dismissable on every page.

---

## License & data

All data in this repository is **synthetic** and hand-crafted for demonstration purposes. No real organizations, real CVEs, or real regulator actions are referenced. Names like "Synthetic Hyperscaler X" or "Regulator Alpha" are intentional placeholders.

---

## Documentation

- [docs/ALPHA_BOUNDARY.md](docs/ALPHA_BOUNDARY.md) — exhaustive list of what alpha does not do
- [docs/PLACEHOLDER_LOGIC.md](docs/PLACEHOLDER_LOGIC.md) — per-module Stage 2 swap path
- [docs/DATA_MODEL.md](docs/DATA_MODEL.md) — schema reference and append-only discipline
