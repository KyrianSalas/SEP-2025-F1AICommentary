import os
import json
import pytest
from unittest.mock import AsyncMock, patch
from fast_app.services.commentary_generator import RealtimeCommentaryGenerator

@pytest.fixture
def generator():
    """Returns an instance of the generator with a fake API key"""
    with patch.dict(os.environ, {"OPENAI_API_KEY": "sk-test-key"}):
        return RealtimeCommentaryGenerator()

@pytest.fixture
def mock_ws():
    """Mock WS"""
    ws = AsyncMock()
    ws.__aiter__.return_value = [] 
    return ws

async def test_connect_sends_session_update(generator, mock_ws):
    with patch("fast_app.services.commentary_generator.connect", new_callable=AsyncMock) as mocked_connect:
        mocked_connect.return_value = mock_ws
        
        await generator.connect()
        assert generator.ws == mock_ws
        assert mock_ws.send.called
        sent_payload = json.loads(mock_ws.send.call_args[0][0])
        assert sent_payload["type"] == "session.update"

async def test_listen_for_ai_responses_forwards_deltas(generator, mock_ws):
    text_content = "Box box box!" 
    mock_events = [
        json.dumps({"type": "response.audio_transcript.delta", "delta": text_content})
    ]
    mock_ws.__aiter__.return_value = mock_events
    generator.ws = mock_ws
    
    mock_frontend = AsyncMock()
    await generator.listen_for_ai_responses(mock_frontend)
    
    mock_frontend.send_json.assert_called_with({
        "type": "commentary_delta", 
        "text": text_content
    })

async def test_push_telemetry_creates_item(generator, mock_ws):
    generator.ws = mock_ws
    await generator.push_telemetry("Verstappen has lost his front right tyre!")
    
    calls = [json.loads(call.args[0]) for call in mock_ws.send.call_args_list]
    assert any(c["type"] == "conversation.item.create" for c in calls)