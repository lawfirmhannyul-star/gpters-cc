"""Generate a card-news character illustration via the Gemini image API.

Usage: python3 scripts/generate_character.py <prompt> <output_path> [style_key]

style_key selects a fixed character descriptor from CHARACTER_STYLES so the same
person recurs across cards (default: "client"). Add new styles here as new
recurring characters are introduced.

Requires GEMINI_API_KEY in the environment (loaded from .env by the caller).

Called once per card set per card role (not just at template-design time): face/
outfit/style stay locked via CHARACTER_STYLES, but pose and background should be
written fresh each time to fit that card set's story. Always eyeball the result
against earlier renders of the same style_key before using it -- outfit color/
pattern, glasses, facial hair can drift between calls even with an identical
style suffix. If it drifts, add explicit constraints to the prompt (e.g. "plain
solid navy blue sweater, no stripes", "no glasses, clean-shaven") and regenerate.
"""
import base64
import json
import os
import sys
import urllib.request

BASE_STYLE = (
    ", flat vector illustration style, warm beige and soft blue color palette, "
    "minimalist modern editorial illustration, no text in image, clean lines, "
    "flat solid color blocks only, no gradient lighting, no glow or ambient light rays, "
    "hard-edged shapes, minimal props in frame -- avoid generic office clutter like "
    "potted plants, mugs, or bookshelves unless the prompt explicitly calls for them"
)

CHARACTER_STYLES = {
    # The consulting client — casual, relatable, the person the story happens to.
    "client": BASE_STYLE + (
        ", consistent with a Korean man in his 40s with short black hair "
        "wearing a navy blue sweater, casual"
    ),
    # 한세영 변호사 — the attorney. Distinct from the client: blazer, more formal,
    # warm-but-professional. Reused across every card where the lawyer appears.
    "lawyer": BASE_STYLE + (
        ", consistent recurring character: a warm and confident Korean male attorney "
        "in his mid-40s, short neat black hair, wearing a well-fitted navy blazer over "
        "a white shirt, approachable professional expression, no tie clutter, "
        "same face and outfit every time"
    ),
}


def generate(prompt: str, out_path: str, style_key: str = "client") -> None:
    api_key = os.environ["GEMINI_API_KEY"]
    style_suffix = CHARACTER_STYLES[style_key]
    body = {
        "model": "gemini-3.1-flash-image",
        "input": [{"type": "text", "text": prompt + style_suffix}],
    }
    req = urllib.request.Request(
        "https://generativelanguage.googleapis.com/v1beta/interactions",
        data=json.dumps(body).encode("utf-8"),
        headers={
            "x-goog-api-key": api_key,
            "Content-Type": "application/json",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=60) as resp:
        data = json.load(resp)

    img_b64 = None
    for step in data.get("steps", []):
        for item in step.get("content", []):
            if item.get("data"):
                img_b64 = item["data"]
    if not img_b64:
        raise RuntimeError(f"No image data in response: {json.dumps(data)[:500]}")

    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "wb") as f:
        f.write(base64.b64decode(img_b64))
    print(f"saved {out_path}")


if __name__ == "__main__":
    style = sys.argv[3] if len(sys.argv) > 3 else "client"
    generate(sys.argv[1], sys.argv[2], style)
