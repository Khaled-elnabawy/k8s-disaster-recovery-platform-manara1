import os
import time

import psycopg2
from flask import Flask, jsonify, request

app = Flask(__name__)


def get_connection():
    return psycopg2.connect(
        host=os.environ.get("POSTGRES_HOST", "postgres"),
        database=os.environ.get("POSTGRES_DB", "appdb"),
        user=os.environ.get("POSTGRES_USER", "appuser"),
        password=os.environ.get("POSTGRES_PASSWORD", ""),
        connect_timeout=3,
    )


def init_db(retries=30, delay_seconds=2):
    """Wait briefly for PostgreSQL to become reachable, then initialize the table."""
    last_error = None
    for attempt in range(retries):
        try:
            with get_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute(
                        "CREATE TABLE IF NOT EXISTS users "
                        "(id SERIAL PRIMARY KEY, name TEXT NOT NULL);"
                    )
            return
        except psycopg2.OperationalError as exc:
            last_error = exc
            if attempt < retries - 1:
                time.sleep(delay_seconds)
    raise RuntimeError("PostgreSQL did not become ready before startup timeout") from last_error


@app.get("/")
def home():
    return jsonify({"status": "running", "service": "demo-app"})


@app.get("/healthz")
def healthz():
    """Liveness endpoint independent of database availability."""
    return jsonify({"status": "ok"})


@app.get("/readyz")
def readyz():
    """Readiness endpoint that verifies the database can answer a simple query."""
    try:
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT 1;")
                cur.fetchone()
    except psycopg2.Error:
        return jsonify({"status": "not-ready", "dependency": "postgres"}), 503
    return jsonify({"status": "ready"})


@app.get("/users")
def get_users():
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT id, name FROM users ORDER BY id;")
            rows = cur.fetchall()
    return jsonify([{"id": row[0], "name": row[1]} for row in rows])


@app.post("/users")
def add_user():
    data = request.get_json(silent=True)
    if not isinstance(data, dict) or not isinstance(data.get("name"), str) or not data["name"].strip():
        return jsonify({"error": "A non-empty name is required"}), 400

    name = data["name"].strip()
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("INSERT INTO users (name) VALUES (%s) RETURNING id;", (name,))
            new_id = cur.fetchone()[0]
    return jsonify({"id": new_id, "name": name}), 201


if __name__ == "__main__":
    init_db()
    app.run(host="0.0.0.0", port=5000)
