#!/usr/bin/env bash
# ------------------------------------------------------------------
# vocal-separator.sh — Wrapper for vocal/instrumental separation.
#
# Usage:
#   ./vocal-separator.sh <input_audio> [additional vocal-separator flags]
#
# Examples:
#   ./vocal-separator.sh song.wav
#   ./vocal-separator.sh song.wav --mdxc_segment_size 64         # lower VRAM usage
#   ./vocal-separator.sh song.wav --output_format MP3            # export as MP3
#   ./vocal-separator.sh song.wav --mdxc_overlap 4               # higher quality, slower
#
# All flags accepted by the underlying tool can be appended after the
# input file. They will override the defaults defined below.
# ------------------------------------------------------------------
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# The upstream binary is named 'audio-separator.exe'
SEPARATOR="$SCRIPT_DIR/venv/Scripts/audio-separator.exe"

if [[ ! -f "$SEPARATOR" ]]; then
  echo "[ERROR] vocal-separator environment not found. Run setup.sh first." >&2
  exit 1
fi

if ! "$SCRIPT_DIR/venv/Scripts/python.exe" -c \
  "import torch; raise SystemExit(0 if torch.cuda.is_available() else 1)" \
  >/dev/null 2>&1; then
  echo "[WARN] No CUDA GPU detected — running on CPU (slow)." >&2
fi

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <input_audio> [vocal-separator arguments]" >&2
  echo "Example: $0 song.wav --mdxc_segment_size 64" >&2
  exit 1
fi

INPUT_FILE="$1"
shift

if [[ ! -f "$INPUT_FILE" ]]; then
  echo "[ERROR] Input file not found: $INPUT_FILE" >&2
  exit 1
fi

mkdir -p "$SCRIPT_DIR/models" "$SCRIPT_DIR/output"

# ------------------------------------------------------------------
# DEFAULT PARAMETERS
# Edit the values below to change separation behaviour.
# Any flag passed on the command line will override these defaults.
# ------------------------------------------------------------------
DEFAULT_ARGS=(
  # Model checkpoint to load.
  # Change this if you download a different Mel-Band RoFormer checkpoint.
  "--model_filename" "mel_band_roformer_instrumental_becruily.ckpt"

  # Directory where model checkpoints are stored.
  "--model_file_dir" "$SCRIPT_DIR/models"

  # Directory where separated stems (vocal / instrumental) are written.
  "--output_dir" "$SCRIPT_DIR/output"

  # Output audio format.
  # Options: WAV, MP3, FLAC, OGG, M4A, etc.
  "--output_format" "WAV"

  # Use FP16 (half precision) on the GPU.
  # Reduces VRAM usage. Disable only if you encounter numerical errors.
  "--use_native_fp16"

  # Override the model's default segment size.
  # Required when setting --mdxc_segment_size manually.
  "--mdxc_override_model_segment_size"

  # Segment size in samples processed per batch.
  # Lower values reduce VRAM usage but increase processing time.
  #   128 — good quality
  #    64 — use this if you get "CUDA out of memory"
  #    32 — last resort for very low-VRAM GPUs
  "--mdxc_segment_size" "128"

  # Number of segments processed simultaneously.
  # Keep at 1 unless you have >16 GB VRAM.
  # Increasing this speeds up processing but multiplies VRAM usage.
  "--mdxc_batch_size" "1"

  # Overlap between adjacent segments (ratio).
  # Higher values reduce boundary artifacts but increase processing time.
  #   2 — default
  #   4 — better quality for complex mixes
  #   8 — maximum quality, significantly slower
  "--mdxc_overlap" "2"
)

echo "--> Separating: $INPUT_FILE"
printf '    For lower memory use: %q %q --mdxc_segment_size 64\n' \
  "$0" "$INPUT_FILE"

# exec replaces this shell process with the Python process.
# This ensures Ctrl+C correctly kills the separator instead of
# leaving a zombie process holding GPU memory.
exec "$SEPARATOR" \
  "$INPUT_FILE" \
  "${DEFAULT_ARGS[@]}" \
  "$@"
