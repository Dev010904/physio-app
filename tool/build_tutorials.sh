#!/usr/bin/env bash
# Builds the tutorial sheets the app plays (assets/tutorials/<id>.webp) and the
# small list posters (assets/tutorials/<id>_poster.webp) from the source clips
# and photos in art/tutorials.
#
# Each sheet holds one rep, start pose to end pose, as up to 25 frames of
# 480 x 480 in rows of 5. The app steps through them in time with the session
# (lib/tutorials/tutorial.dart), so the frame counts printed here must match
# the counts there.
#
# Needs ffmpeg with libwebp:  FFMPEG=/path/to/ffmpeg bash tool/build_tutorials.sh
# One way to get it: uv run --with imageio-ffmpeg python -c "import imageio_ffmpeg; print(imageio_ffmpeg.get_ffmpeg_exe())"
set -euo pipefail
cd "$(dirname "$0")/.."
FF="${FFMPEG:-ffmpeg}"
SRC=art/tutorials
OUT=assets/tutorials
mkdir -p "$OUT"

# id, then the first and last frame of the 16 fps clip to use and the step
# between frames. Clips that bounce before the clean rep start later.
# "photos" means there is no usable clip yet: the sheet is the start and end
# photo, and the app cross-fades between them.
while read -r id first last step; do
  if [ "$first" = photos ]; then
    "$FF" -v error -y -i "$SRC/frames/${id}_start.png" -i "$SRC/frames/${id}_end.png" \
      -filter_complex "[0]scale=480:480[a];[1]scale=480:480[b];[a][b]hstack" \
      -frames:v 1 -c:v libwebp -quality 82 "$OUT/$id.webp"
    count=2
  else
    count=$(( (last - first) / step + 1 ))
    rows=$(( (count + 4) / 5 ))
    "$FF" -v error -y -i "$SRC/videos/$id.mp4" \
      -vf "select='between(n\,$first\,$last)*not(mod(n-$first\,$step))',tile=5x$rows" \
      -frames:v 1 -c:v libwebp -quality 82 "$OUT/$id.webp"
  fi
  # Poster for lists: the end pose with its muscles lit.
  "$FF" -v error -y -i "$SRC/frames/${id}_end.png" -vf scale=200:200 \
    -frames:v 1 -c:v libwebp -quality 82 "$OUT/${id}_poster.webp"
  echo "$id: $count frames"
done <<'EOF'
wall_squat 0 48 2
straight_leg_raise 24 48 1
heel_raise 24 48 1
glute_bridge 0 48 2
clamshell 0 48 2
quad_set 0 48 2
cat_cow 16 48 2
chin_tuck photos
pendulum photos
calf_stretch 0 48 2
EOF
