from fastapi.testclient import TestClient
from fast_app.main import app
import pytest

client = TestClient(app)

def test_root():
    response = client.get("/")
    assert response.status_code == 200
    print(response.json())
    assert response.json() == {"message": "F1 Commentary Generator API", "status": "running"}

def test_api_working():
    response = client.get("/api/")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}

def test_list_csv_files():
    response = client.get("/api/csv/files")
    assert response.status_code == 200
    data = response.json()
    assert "files" in data
    assert isinstance(data["files"], list)

def test_upload_rejects_non_csv():
    response = client.post(
        "/api/csv/upload",
        files={"file": ("test.txt", b"some content", "text/plain")}
    )
    assert response.status_code == 400
    assert "csv" in response.json()["detail"].lower()

def test_upload_accepts_csv():
    response = client.post(
        "/api/csv/upload",
        files={"file": ("test.csv", b"col1,col2\n1,2\n3,4", "text/csv")}
    )
    assert response.status_code == 200
    assert response.json()["filename"] == "test.csv"

def test_session_fastf1_missing_params():
    response = client.get("/api/session?source=fastf1")
    assert response.status_code == 400
    assert "year" in response.json()["detail"].lower() or "location" in response.json()["detail"].lower()

def test_session_csv_file_not_found():
    response = client.get("/api/session?source=csv&csv_filename=nonexistent.csv")
    assert response.status_code == 404
    assert "not found" in response.json()["detail"].lower()

def test_session_csv_path_traversal():
    response = client.get("/api/session?source=csv&csv_filename=../etc/passwd")
    assert response.status_code == 400
    assert "invalid" in response.json()["detail"].lower()

def test_get_races():
    response = client.get("/api/races")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, dict)

def test_websocket_telemetry_rejects_invalid_session():
    with client.websocket_connect("/api/ws/telemetry?session_id=invalid-session-id") as websocket:
        with pytest.raises(Exception):
            websocket.receive_json()
