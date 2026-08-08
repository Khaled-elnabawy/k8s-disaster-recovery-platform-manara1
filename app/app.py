from flask import Flask, jsonify, request
import psycopg2
import os

app = Flask(__name__)

def get_connection():
    return psycopg2.connect(
        host="postgres",
        database=os.environ.get("POSTGRES_DB", "appdb"),
        user=os.environ.get("POSTGRES_USER", "admin"),
        password=os.environ.get("POSTGRES_PASSWORD", "admin123"),
    )

def init_db():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("CREATE TABLE IF NOT EXISTS users (id SERIAL PRIMARY KEY, name TEXT);")
    conn.commit()
    cur.close()
    conn.close()

@app.route("/")
def home():
    return jsonify({"status": "running", "service": "demo-app"})

@app.route("/users", methods=["GET"])
def get_users():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("SELECT id, name FROM users;")
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return jsonify([{"id": r[0], "name": r[1]} for r in rows])

@app.route("/users", methods=["POST"])
def add_user():
    data = request.get_json()
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("INSERT INTO users (name) VALUES (%s) RETURNING id;", (data["name"],))
    new_id = cur.fetchone()[0]
    conn.commit()
    cur.close()
    conn.close()
    return jsonify({"id": new_id, "name": data["name"]}), 201

if __name__ == "__main__":
    init_db()
    app.run(host="0.0.0.0", port=5000)
