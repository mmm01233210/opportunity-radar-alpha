# Opportunity Radar Alpha — Makefile
# All commands assume you are at the repo root.

SHELL := /bin/bash
ENV_FILE := .env

# Load .env if it exists
ifneq (,$(wildcard $(ENV_FILE)))
    include $(ENV_FILE)
    export
endif

.PHONY: help up down migrate seed process-all dev-backend dev-frontend \
        verify-audit reset install-backend install-frontend logs psql clean \
        test-backend

help:
	@echo "Opportunity Radar Alpha — local commands"
	@echo ""
	@echo "  make up                 - start postgres (docker compose)"
	@echo "  make down               - stop postgres"
	@echo "  make install-backend    - install backend python deps"
	@echo "  make install-frontend   - install frontend node deps"
	@echo "  make migrate            - run alembic migrations"
	@echo "  make seed               - load synthetic seed data"
	@echo "  make process-all        - run pipeline over all signals"
	@echo "  make dev-backend        - run FastAPI dev server (port 8000)"
	@echo "  make dev-frontend       - run Next.js dev server (port 3000)"
	@echo "  make verify-audit       - verify audit-chain integrity"
	@echo "  make test-backend       - run backend tests"
	@echo "  make psql               - open psql against local db"
	@echo "  make logs               - tail postgres logs"
	@echo "  make reset              - drop db, re-migrate, re-seed, re-process"
	@echo "  make clean              - down + remove volumes (DESTRUCTIVE)"

up:
	docker compose up -d
	@echo "waiting for postgres to be ready..."
	@until docker compose exec -T postgres pg_isready -U $${POSTGRES_USER:-alpha} -d $${POSTGRES_DB:-opportunity_radar_alpha} > /dev/null 2>&1; do \
	  sleep 1; \
	done
	@echo "postgres ready."

down:
	docker compose down

logs:
	docker compose logs -f postgres

psql:
	docker compose exec postgres psql -U $${POSTGRES_USER:-alpha} -d $${POSTGRES_DB:-opportunity_radar_alpha}

install-backend:
	cd backend && python -m venv .venv && \
	. .venv/bin/activate && \
	pip install --upgrade pip && \
	pip install -e .

install-frontend:
	cd frontend && npm install

migrate:
	cd backend && . .venv/bin/activate && alembic upgrade head

seed:
	cd backend && . .venv/bin/activate && python -m app.seed.seed_runner

process-all:
	cd backend && . .venv/bin/activate && python -m app.scripts.process_all

dev-backend:
	cd backend && . .venv/bin/activate && \
	uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

dev-frontend:
	cd frontend && npm run dev

verify-audit:
	cd backend && . .venv/bin/activate && python -m app.scripts.verify_audit

test-backend:
	cd backend && . .venv/bin/activate && pytest -q

reset: down up migrate seed process-all
	@echo "reset complete."

clean:
	docker compose down -v
