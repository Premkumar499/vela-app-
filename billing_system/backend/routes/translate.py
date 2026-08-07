"""
Local translation endpoint — no external API needed.

Uses the built-in Tanglish/Tamil transliteration engine (language_utils.py).

POST /translate/
Body: { "texts": ["Rice", "Arisi"], "target": "ta" }
Returns: { "success": true, "translations": ["ரைஸ்", "அரிசி"] }
"""

from flask import Blueprint, request, jsonify
from services.language_utils import (
    detect_language,
    transliterate_tanglish_to_tamil,
    Language,
)

translate_bp = Blueprint("translate", __name__)


def _to_tamil(text: str) -> str:
    """Best-effort convert any text to Tamil script."""
    lang = detect_language(text)
    if lang == Language.tamil:
        return text                          # already Tamil
    if lang == Language.tanglish:
        return transliterate_tanglish_to_tamil(text)
    # English — transliterate anyway (phonetic approximation)
    return transliterate_tanglish_to_tamil(text)


@translate_bp.post("/translate/")
def translate():
    data   = request.get_json(silent=True) or {}
    texts  = data.get("texts", [])

    if not texts:
        return jsonify({"success": False, "message": "No texts provided"}), 400

    translations = [_to_tamil(str(t)) for t in texts]

    return jsonify({"success": True, "translations": translations})
