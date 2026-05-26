import os
import json

try:
    # websockets >= 13
    from websockets.asyncio.client import connect
except ModuleNotFoundError:
    # websockets <= 12
    from websockets.client import connect

class RealtimeCommentaryGenerator:
    def __init__(self):
        self.api_key = os.getenv("OPENAI_API_KEY")
        self.model = os.getenv("OPENAI_REALTIME_MODEL", "gpt-4o-mini-realtime-preview")
        self.voice = os.getenv("OPENAI_VOICE", "ash")
        self.temperature = float(os.getenv("OPENAI_TEMPERATURE", "0.7"))
        self.prompt_id = os.getenv("OPENAI_PROMPT_ID")
        self.prompt_version = os.getenv("OPENAI_PROMPT_VERSION")
        self.use_hosted_prompt = os.getenv("OPENAI_USE_HOSTED_PROMPT", "false").lower() in {
            "1", "true", "yes", "on"
        }
        self.prompt_variables = self._load_prompt_variables(
            os.getenv("OPENAI_PROMPT_VARIABLES_JSON", "")
        )
        self.url = f"wss://api.openai.com/v1/realtime?model={self.model}"
        self.ws = None
        self.paused = False
        self.is_speaking = False

    def _load_prompt_variables(self, raw_json: str):
        if not raw_json:
            return {}
        try:
            parsed = json.loads(raw_json)
            return parsed if isinstance(parsed, dict) else {}
        except json.JSONDecodeError:
            print("Invalid OPENAI_PROMPT_VARIABLES_JSON. Ignoring variables.")
            return {}

    def _default_instructions(self):
        return (
            "You are 'Crofty', a legendary British F1 lead commentator. "
            "Your voice is deep, energetic, and professional. "
            "CRITICAL: Respond with ONLY 1 SENTENCE per response. "
            "STYLE RULES: "
            "1. Each response is exactly 1 sentence (5-12 words). Examples: 'Hamilton into the DRS zone!' 'Masterful braking into Turn 3!' 'Big speed down the straight!' "
            "2. Always end with a period, exclamation mark, or question mark. "
            "3. After each sentence, STOP and wait for the next telemetry update. "
            "4. If speed > 300km/h in straight: 'Incredible pace down the straight!' "
            "5. If hard braking detected: 'Standing on the brakes into the corner!' "
            "6. If smooth corner: 'Precision through the turn!' "
            "7. Never generate multiple sentences. Never continue talking after your sentence ends. "
            "8. Never say 'I am an AI'. Stay in character as 'Crofty' in the F1 commentary box. "
            "9. Never say phrases like 'it looks like', 'the telemetry shows', or 'the data indicates'. "
            "10. Sound like live race radio commentary, not an analyst recap."
        )

    def _build_session_config(self):
        if self.use_hosted_prompt and self.prompt_id:
            prompt = {"id": self.prompt_id}
            if self.prompt_version:
                prompt["version"] = self.prompt_version
            if self.prompt_variables:
                prompt["variables"] = self.prompt_variables
            return {"prompt": prompt}

        return {
            "instructions": self._default_instructions(),
            "modalities": ["text", "audio"],
            "voice": self.voice,
            "input_audio_transcription": {"model": "whisper-1"},
            "turn_detection": None,
            "temperature": self.temperature,
        }

    async def connect(self):
        """Establish the 'Live' connection to the AI booth."""
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "OpenAI-Beta": "realtime=v1"
        }
        
        self.ws = await connect(
            self.url,
            additional_headers=headers
        )

        session_config = self._build_session_config()

        await self.ws.send(json.dumps({
            "type": "session.update",
            "session": session_config
        }))
        if self.prompt_id:
            print(
                f"AI session configured from hosted prompt {self.prompt_id}"
                f"{f' (v{self.prompt_version})' if self.prompt_version else ''}."
            )
        elif self.prompt_id and not self.use_hosted_prompt:
            print(
                "OPENAI_PROMPT_ID detected but OPENAI_USE_HOSTED_PROMPT is not enabled; "
                "using local Crofty instructions."
            )
        print("AI Commentator has joined the session.")

    async def push_telemetry(self, telemetry_snapshot: str):
        if not self.ws:
            print("AI Commentator offline. Reconnecting...")
            await self.connect()

        try:
            if not self.is_speaking:
                user_update = (
                    "Live race snapshot. Keep it punchy and dramatic in Crofty style. "
                    "Do not mention telemetry, data, dashboard, or that you are inferring. "
                    f"{telemetry_snapshot}"
                )
                await self.ws.send(json.dumps({
                    "type": "conversation.item.create",
                    "item": {
                        "type": "message",
                        "role": "user",
                        "content": [{"type": "input_text", "text": user_update}]
                    }
                }))
                await self.ws.send(json.dumps({"type": "response.create"}))
        except Exception as e:
            print(f"Error pushing to AI: {e}")
            self.ws = None

    async def update_ai_speech_pace(self, multiplier):
        if not self.ws:
            return

        # Create a dynamic prompt based on speed
        pace_instruction = "Speak at an energetic, natural pace."
        if multiplier >= 2:
            pace_instruction = f"The race is at {multiplier}x speed! Speak faster and more intensely, but keep it natural."
        
        await self.ws.send(json.dumps({
            "type": "session.update",
            "session": {
                "instructions": (
                    "You are 'Crofty', the F1 lead commentator. "
                    f"{pace_instruction} "
                    "Use exactly 1 short race-call sentence. "
                    "Do not mention telemetry, data, or AI."
                )
            }
        }))
        print(f"AI instructions updated for {multiplier}x speed.")

    async def listen_for_ai_responses(self, frontend_ws):
        print("Listener started...")
        try:
            async for message in self.ws:
                if self.paused:
                    continue

                event = json.loads(message)
                etype = event.get("type")

                # Track the speaking state to prevent overlapping or cutting off audio
                if etype == "response.created":
                    self.is_speaking = True
                elif etype in ("response.done", "response.cancelled", "response.failed"):
                    self.is_speaking = False

                if etype == "response.audio_transcript.delta":
                    await frontend_ws.send_json({
                        "type": "commentary_delta",
                        "text": event.get("delta")
                    })

                elif etype == "response.audio.delta":
                    print(f"Audio delta received: {len(event.get('delta', b''))} bytes")
                    await frontend_ws.send_json({
                        "type": "audio_delta",
                        "audio": event.get("delta")
                    })
                
                elif etype == "response.done":
                    await frontend_ws.send_json({"type": "commentary_done"})

        except Exception as e:
            print(f"Listener Error: {e}")
