# Tutorial sources

The app plays `assets/tutorials/<id>.webp`, built from these files by
`tool/build_tutorials.sh`. Nothing in this folder ships in the app.

Each tutorial was made in two steps (2026-10-19 and 2026-10-20):

1. **Frames** (`frames/`): start and end images generated with Canva AI image
   generation (Magic Media) in the owner's Canva account. Every frame uses the
   wall sit end image as the reference, so the same person, outfit and studio
   appear throughout. Muscle glow: orange = working, violet = stretching,
   teal = loosening.
2. **Motion** (`videos/`): Wan 2.2 first-last-frame interpolation (Apache-2.0)
   on the Hugging Face Space `mcp-tools/wan-2-2-first-last-frame`, run from the
   owner's Hugging Face account (opsongs91). 480 x 480, 16 fps, 3 s.

Draft content: form and muscle highlights still need review by a physiotherapist.

| Exercise | Start frame (Canva media) | End frame (Canva media) | Clip used in the app |
| --- | --- | --- | --- |
| wall_squat | MAHYbjVpEYw | MAHYbvZXzgw | frames 0-48 |
| straight_leg_raise | MAHYbtLTuR4 | MAHYblakjL0 | frames 24-48 (the clip lifts once without the glow first) |
| heel_raise | MAHYbg31CXg | MAHYbn3t2ow | frames 24-48 (the clip bobs before the clean rise) |
| glute_bridge | MAHYbld3yWs | MAHYbvPwcLI | frames 0-48 |
| clamshell | MAHYbgq0Hn0 | MAHYbhNpcrw | frames 0-48 |
| quad_set | MAHYbu3FlVw | MAHYbneykD4 | frames 0-48 |
| cat_cow | MAHYbt1zK2k (cow) | MAHYbrqJclI (cat) | frames 16-48 (deep arch to round) |
| chin_tuck | MAHYbqgcvI0 | MAHYbkAFoPo | no clip yet: photos cross-faded |
| pendulum | MAHYbgceLgg | MAHYbs-qBpE | no clip yet: photos cross-faded |
| calf_stretch | MAHYbgQlYQE | MAHYbtwz3cc | frames 0-48 |

The first pendulum clip was rejected and deleted: the arm swung up to
shoulder height behind the body, which is not a relaxed pendulum. The chin
tuck clip is waiting for the next free ZeroGPU quota.
