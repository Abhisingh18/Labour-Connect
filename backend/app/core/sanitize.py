"""Input sanitization for free-text fields (XSS / HTML-injection defence).

Strips HTML tags and neutralises stray angle brackets. We sanitise on input as
defence-in-depth; clients (Flutter, React) also escape on render.
"""
import re

_TAG_RE = re.compile(r"<[^>]*>")
_CTRL_RE = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f]")


def clean_text(value: str | None) -> str | None:
    if value is None:
        return None
    # Remove anything that looks like an HTML/script tag.
    cleaned = _TAG_RE.sub("", value)
    # Neutralise leftover angle brackets and control chars.
    cleaned = cleaned.replace("<", "").replace(">", "")
    cleaned = _CTRL_RE.sub("", cleaned)
    return cleaned.strip()
