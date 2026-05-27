#!/usr/bin/env bash
# Generates 3 conversion-optimized product images for the eSUN PLA-Basic Aqua landing page
# using Google's Nano Banana (Gemini 2.5 Flash Image) via OpenRouter.
set -euo pipefail

: "${OPENROUTER_API_KEY:?OPENROUTER_API_KEY must be set}"

cd "$(dirname "$0")"
mkdir -p generated

gen() {
  local name="$1" prompt="$2"
  echo "→ $name"
  local resp
  resp=$(curl -fsS https://openrouter.ai/api/v1/chat/completions \
    -H "Authorization: Bearer $OPENROUTER_API_KEY" \
    -H 'Content-Type: application/json' \
    -H 'HTTP-Referer: https://nichtagentur.github.io/3djake-summer-aqua/' \
    -H 'X-Title: 3DJake Aqua Landing' \
    -d "$(jq -n --arg p "$prompt" '{
      model: "google/gemini-2.5-flash-image",
      modalities: ["image","text"],
      messages: [{role:"user", content:$p}]
    }')")

  # Extract first image (data URL or plain URL)
  local img
  img=$(printf '%s' "$resp" | jq -r '.choices[0].message.images[0].image_url.url // empty')
  if [ -z "$img" ]; then
    echo "no image returned for $name"; echo "$resp" | jq '.' | head -40; return 1
  fi

  if [[ "$img" == data:* ]]; then
    # data:image/png;base64,XXXX
    local ext="${img#data:image/}"; ext="${ext%%;*}"
    printf '%s' "${img#*,}" | base64 -d > "generated/${name}.${ext}"
    echo "  saved generated/${name}.${ext}"
  else
    curl -fsS -o "generated/${name}.png" "$img"
    echo "  saved generated/${name}.png"
  fi
}

PROMPT_HERO='Hero product photography of a 1kg 3D-printer filament spool. The spool has a sturdy natural CARDBOARD core (light brown / kraft paper colored, NOT plastic) and is tightly wound with bright translucent AQUA-cyan PLA filament (color #5fd1d6). The spool has a small white "eSUN PLA-Basic" label on the cardboard. Studio shot on a clean off-white seamless background with a soft summer-light gradient toward teal in the upper-right corner. One subtle ray of warm sunlight grazes the top edge. Crisp focus on the filament texture, shallow depth of field, premium e-commerce look, sharp shadows, 4k, square 1:1 framing, centered composition, photoreal, no text overlays, no logos other than eSUN, no people.'

PROMPT_LIFESTYLE='Lifestyle product photo: a beautifully 3D-printed translucent AQUA-cyan (color #5fd1d6) geometric vase or organic-shaped planter sitting on a warm light-wood desk near a sunny window. Soft natural summer daylight, a small fresh green plant inside the vase, a few visible 3d-print layer lines on the surface to make clear it was 3d printed (subtle, premium look not amateurish), one out-of-focus 1kg cardboard-core filament spool with AQUA filament in the background. Bright, airy, Scandinavian interior vibe with hints of teal in the wall paint. Photoreal, square 1:1, 4k, no text, no watermarks, e-commerce inspirational shot.'

PROMPT_MACRO='Extreme close-up macro photography of bright translucent AQUA-cyan PLA 3D printer filament (color #5fd1d6), 1.75 mm diameter, winding off a kraft-paper cardboard spool. You can see the smooth glossy surface of the plastic strand, a clean diagonal composition with the filament strand going from lower-left to upper-right, shallow depth of field with the foreground strand in tack-sharp focus and the wound spool blurred behind. Crisp natural daylight, slight teal rim light, professional product macro, square 1:1 framing, 4k, photoreal, no text, no people.'

gen hero "$PROMPT_HERO"
gen lifestyle "$PROMPT_LIFESTYLE"
gen macro "$PROMPT_MACRO"

ls -la generated/
