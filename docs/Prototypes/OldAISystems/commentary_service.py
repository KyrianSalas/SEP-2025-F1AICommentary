from openai import OpenAI
import os
from dotenv import load_dotenv
from models.commentary_models import TelemetryData

load_dotenv()  # Load environment variables from .env file


class CommentaryService:
    """Service to generate F1-style commentary from telemetry.

    Behavior:
    - If OPENAI_API_KEY or OPEN_API_KEY is set, uses the real OpenAI client.
    - If no API key is present, uses a deterministic fallback that doesn't call the network
      (useful for local testing and CI without secrets).
    """

    def __init__(self):
        # Support both common env var names for backward compatibility
        self.api_key = os.getenv("OPENAI_API_KEY") or os.getenv("OPEN_API_KEY")

        if self.api_key:
            self.client = OpenAI(api_key=self.api_key)
            self.model = os.getenv("OPENAI_MODEL", "gpt-4o-mini")
        else:
            # No API key: use a stubbed client (None) and deterministic behavior
            self.client = None
            self.model = None

        self.style_prompts = {
            "crofty": (
                "You are David Croft (Crofty), the energetic and enthusiastic lead F1 commentator. "
                "Create exciting, fast-paced commentary with dramatic flair. Use signature phrases and build tension. "
                "Be passionate about every moment, even small ones. Keep it brief (1-2 sentences max)."
            ),
            "brundle": (
                "You are Martin Brundle, the analytical F1 commentator and former driver. "
                "Provide technical insights with a driver's perspective. Focus on racing lines, car behavior, "
                "and driving technique. Use phrases like 'as a driver...' Be insightful but concise (1-2 sentences max)."
            ),
            "murray_walker": (
                "You are Murray Walker, the legendary passionate F1 commentator. "
                "Use dramatic and enthusiastic language with incredible passion. Be excited about everything! "
                "Occasionally mix up minor details but always with tremendous energy. Keep it brief (1-2 sentences max)."
            ),
            "alex_jacques": (
                "You are Alex Jacques, the modern energetic F1 commentator. "
                "Be sharp, witty, and knowledgeable. Build tension naturally and use contemporary language. "
                "Capture the excitement of modern F1. Keep it concise (1-2 sentences max)."
            ),
        }

    def _format_telemetry_prompt(self, telemetry: TelemetryData, context: str | None = None) -> str:
        """Create a user prompt from telemetry and optional context."""
        prompt_lines = [
            f"Current telemetry snapshot:",
            f"- Speed: {telemetry.ground_speed:.1f} km/h",
            f"- RPM: {telemetry.engine_rpm} rpm",
            f"- Gear: {telemetry.gear}",
            f"- Throttle: {telemetry.throttle_pos:.0f}%",
            f"- Brake: {telemetry.brake_pos:.0f}%",
            f"- Position: P{telemetry.position}",
            f"- Lap time: {telemetry.lap_time:.2f}s",
        ]
        if context:
            prompt_lines.append(f"Context: {context}")
        return "\n".join(prompt_lines)

    def _fake_commentary(self, telemetry: TelemetryData, style: str) -> str:
        """Return a deterministic, short commentary string used when no API key is configured."""
        base = {
            "crofty": "What a moment!",
            "brundle": "Technically, this looks interesting.",
            "murray_walker": "Brilliant! Simply brilliant!",
            "alex_jacques": "That's a neat bit of driving there.",
        }.get(style, "Nice move!")

        return (
            f"{base} At {telemetry.ground_speed:.0f} km/h in gear {telemetry.gear}, "
            f"RPM {telemetry.engine_rpm} — lap {telemetry.lap_time:.2f}s."
        )

    def generate_commentary(
        self,
        telemetry: TelemetryData,
        style: str = "crofty",
        context: str | None = None,
        temperature: float = 0.8,
        max_completion_tokens: int = 150,
    ) -> str:
        """Generate F1-style commentary from telemetry data.

        If no OpenAI API key is configured, returns a deterministic local string (no network).
        """
        system_prompt = self.style_prompts.get(style, self.style_prompts["crofty"])
        user_prompt = self._format_telemetry_prompt(telemetry, context)

        # Offline/test fallback
        if self.client is None:
            return self._fake_commentary(telemetry, style)

        # When an API key is present, call the OpenAI client.
        # If the model is not available or the request fails, fall back to a local deterministic
        # commentary so tests and local runs keep working without requiring model access.
        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt},
                ],
                temperature=temperature,
                max_tokens=max_tokens,
            )

            # Attempt to return the canonical content
            try:
                return response.choices[0].message.content
            except Exception:
                return str(response)
        except Exception as e:
            # Log the error to stdout for debugging and return deterministic fallback
            print(f"OpenAI API error - falling back to local commentary: {e}")
            return self._fake_commentary(telemetry, style)

    def stream_commentary(
        self,
        telemetry: TelemetryData,
        style: str = "crofty",
        context: str | None = None,
        temperature: float = 0.8,
    ):
        """Stream commentary token by token when possible.

        Yields deterministic single-chunk commentary when no API key is configured.
        """
        system_prompt = self.style_prompts.get(style, self.style_prompts["crofty"])
        user_prompt = self._format_telemetry_prompt(telemetry, context)

        if self.client is None:
            # Yield the full fake commentary as a single chunk
            yield self._fake_commentary(telemetry, style)
            return

        try:
            stream = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt},
                ],
                temperature=temperature,
                max_tokens=150,
                stream=True,
            )

            for chunk in stream:
                if chunk.choices[0].delta.content:
                    yield chunk.choices[0].delta.content
        except Exception as e:
            # If streaming fails (e.g., permission / model not available), fall back to a single chunk
            print(f"OpenAI streaming error - falling back to local commentary: {e}")
            yield self._fake_commentary(telemetry, style)



