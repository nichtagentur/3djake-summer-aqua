#!/usr/bin/env bash
# Generate a 5-second 360° product video of the eSUN Aqua filament spool using OpenAI Sora-2.
# Includes native audio (mechanical whoosh + soft synth + click), 3DJake CI styling.
set -euo pipefail
: "${OPENAI_API_KEY:?OPENAI_API_KEY must be set}"
cd "$(dirname "$0")"

PROMPT='Premium e-commerce product video, photoreal studio shot, 5 seconds.
Subject: a 1kg 3D-printer filament spool with a natural KRAFT CARDBOARD CORE (light brown) tightly wound with bright translucent AQUA-cyan PLA filament (color resembles swimming-pool water, hex #5fd1d6). A small white "eSUN PLA-Basic" label is visible on the cardboard.
Action: the spool sits centered on a glass turntable and performs ONE smooth, continuous 360-degree rotation around its vertical axis over the full 5 seconds. Steady, mechanical, precise speed — no wobble.
Camera: locked-off slight low angle, very subtle slow push-in, shallow depth of field.
Lighting: clean white studio softbox key from upper-left, soft teal rim light (#00838a) from upper-right hitting the filament edge, gentle warm fill. Light catches the glossy aqua plastic strands as the spool turns.
Background: off-white seamless backdrop with a soft TEAL #00838a vertical gradient on the right side. Floating dust-light particles and a few tiny water droplets in the air for a summer/refreshing vibe.
Mood: technical, premium, dynamic, refreshing — like a high-end consumer-tech reveal.
Audio: gentle mechanical turntable whoosh as the spool rotates, a clean modern synth pad in the background, a soft sub-bass thump on rotation start, a crisp "click" at the end as the rotation completes. No voiceover, no music vocals.
Constraints: no text overlays, no logos other than the small eSUN label, no people, no hands, sharp focus on the spool, premium 3D-printer brand aesthetic.'

echo "▶ Creating video job (sora-2, 5s, 1280x720)…"
JOB=$(curl -fsS https://api.openai.com/v1/videos \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H 'Content-Type: application/json' \
  -d "$(jq -n --arg p "$PROMPT" '{model:"sora-2", prompt:$p, seconds:"4", size:"1280x720"}')")

ID=$(printf '%s' "$JOB" | jq -r .id)
echo "  job id: $ID"
[ -z "$ID" ] || [ "$ID" = "null" ] && { echo "$JOB" | jq .; exit 1; }

echo "▶ Polling status…"
while :; do
  S=$(curl -fsS "https://api.openai.com/v1/videos/$ID" -H "Authorization: Bearer $OPENAI_API_KEY")
  STATUS=$(printf '%s' "$S" | jq -r .status)
  PROG=$(printf '%s' "$S" | jq -r '.progress // 0')
  printf '  status=%s progress=%s%%\n' "$STATUS" "$PROG"
  case "$STATUS" in
    completed) break;;
    failed|cancelled) echo "$S" | jq .; exit 1;;
  esac
  sleep 8
done

echo "▶ Downloading video…"
curl -fsS "https://api.openai.com/v1/videos/$ID/content?variant=video" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -o product-video.mp4

ls -la product-video.mp4
ffprobe -v error -show_format -show_streams product-video.mp4 2>/dev/null | grep -E 'duration|codec_name|width|height' | head -10 || true
echo "✓ Done."
