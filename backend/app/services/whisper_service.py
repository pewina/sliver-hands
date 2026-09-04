from __future__ import annotations

import os
import tempfile
from pathlib import Path

from faster_whisper import WhisperModel


class WhisperService:
    def __init__(self) -> None:
        model_name = os.getenv(
            "WHISPER_MODEL",
            "base",
        )

        print(
            f"🎤 Loading Whisper model: {model_name}"
        )

        self.model = WhisperModel(
            model_name,
            device="cpu",
            compute_type="int8",
        )

        print(
            "🎤 Whisper model loaded successfully."
        )

    def transcribe(
        self,
        audio_bytes: bytes,
        filename: str,
        language: str | None = None,
    ) -> dict:
        suffix = Path(filename).suffix or ".wav"

        temp_path: str | None = None

        try:
            with tempfile.NamedTemporaryFile(
                suffix=suffix,
                delete=False,
            ) as temp:
                temp.write(audio_bytes)
                temp.flush()
                temp_path = temp.name

            print(
                "🎤 Whisper: processing "
                f"{len(audio_bytes)} bytes"
            )

            whisper_language = self._normalize_language(
                language
            )

            segments, info = self.model.transcribe(
                temp_path,
                language=whisper_language,
                beam_size=5,
                vad_filter=True,
            )

            transcript = " ".join(
                segment.text.strip()
                for segment in segments
                if segment.text.strip()
            ).strip()

            detected_language = (
                info.language or "unknown"
            )

            print(
                f"🎤 Whisper language: "
                f"{detected_language}"
            )

            print(
                f"🎤 Whisper transcript: "
                f"{transcript}"
            )

            return {
                "transcript": transcript,
                "language": detected_language,
            }

        finally:
            if temp_path:
                try:
                    os.unlink(temp_path)
                except OSError:
                    pass

    @staticmethod
    def _normalize_language(
        language: str | None,
    ) -> str | None:
        if not language:
            return None

        mapping = {
            "english": "en",
            "tamil": "ta",
            "hindi": "hi",
            "telugu": "te",
            "malayalam": "ml",
            "kannada": "kn",
            "bengali": "bn",
            "marathi": "mr",
            "gujarati": "gu",
            "punjabi": "pa",
        }

        value = language.strip().lower()

        return mapping.get(value, value)


_whisper_service: WhisperService | None = None


def get_whisper() -> WhisperService:
    global _whisper_service

    if _whisper_service is None:
        _whisper_service = WhisperService()

    return _whisper_service