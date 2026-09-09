#!/usr/bin/env bash
# Build the local Vocal Separator environment described in README.md.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "--> Checking system dependencies (Python 3.12, FFmpeg)..."
if ! py -3.12 --version > /dev/null 2>&1; then
  echo "    [ERROR] Python 3.12 is required. Install it with:" >&2
  echo "            winget install --exact --id Python.Python.3.12" >&2
  exit 1
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "    [ERROR] FFmpeg must be available on PATH before running Vocal Separator." >&2
  exit 1
fi

PYTHON="venv/Scripts/python.exe"
SEPARATOR="venv/Scripts/audio-separator.exe"

echo "--> Setting up Python virtual environment..."
if [[ -f "$PYTHON" ]]; then
  if ! "$PYTHON" -c 'import sys; raise SystemExit(0 if sys.version_info[:2] == (3, 12) else 1)' >/dev/null 2>&1; then
    DETECTED_VERSION="$("$PYTHON" --version 2>&1 || echo "unknown Python version")"
    echo "    [ERROR] Existing venv uses $DETECTED_VERSION; Python 3.12 is required." >&2
    echo "            Preserve it by renaming it, then run setup.sh again:" >&2
    echo "            mv venv venv-incompatible" >&2
    exit 1
  fi
elif [[ -d "venv" ]]; then
  echo "    [ERROR] Existing venv directory is incomplete or damaged." >&2
  echo "            Preserve it by renaming it, then run setup.sh again:" >&2
  echo "            mv venv venv-incomplete" >&2
  exit 1
else
  py -3.12 -m venv venv
fi

echo "--> Upgrading pip, setuptools, and wheel..."
"$PYTHON" -m pip install --upgrade pip setuptools wheel

echo "--> Detecting an NVIDIA CUDA driver..."
CUDA_REQUESTED=false
if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1; then
  CUDA_REQUESTED=true
fi

echo "--> Installing vocal-separator dependencies and audioread..."
# Note: The upstream pip package is literally named 'audio-separator'.
if [[ "$CUDA_REQUESTED" == true ]]; then
  echo "    NVIDIA driver detected — installing GPU dependencies."
  "$PYTHON" -m pip install "audio-separator[gpu]==0.47.0"
else
  echo "    [WARN] No usable NVIDIA driver detected — installing CPU dependencies."
  echo "           Separation will work but will be significantly slower."
  "$PYTHON" -m pip install "audio-separator==0.47.0"
fi
"$PYTHON" -m pip install audioread==3.1.0

if [[ "$CUDA_REQUESTED" == true ]]; then
  echo "--> Installing PyTorch with CUDA 13.0 support (this may take a few minutes)..."
  "$PYTHON" -m pip install --force-reinstall \
    torch==2.14.0 torchvision==0.29.0 \
    --index-url https://download.pytorch.org/whl/cu130
else
  echo "--> Installing CPU-only PyTorch..."
  "$PYTHON" -m pip install --force-reinstall \
    torch==2.14.0 torchvision==0.29.0 \
    --index-url https://download.pytorch.org/whl/cpu
fi

if [[ "$CUDA_REQUESTED" == true ]] && \
  ! "$PYTHON" -c "import torch; raise SystemExit(0 if torch.cuda.is_available() else 1)" \
    >/dev/null 2>&1; then
  echo "    [WARN] CUDA could not be initialized — replacing GPU PyTorch with the CPU build."
  echo "           Separation will work but will be significantly slower."
  "$PYTHON" -m pip install --force-reinstall \
    torch==2.14.0 torchvision==0.29.0 \
    --index-url https://download.pytorch.org/whl/cpu
fi

echo "--> Verifying pip dependency tree..."
"$PYTHON" -m pip check

echo "--> Creating required directories (input, output, models)..."
mkdir -p input output models

echo "--> Verifying PyTorch..."
"$PYTHON" - <<'PY'
import torch
cuda_available = torch.cuda.is_available()
print("PyTorch:", torch.__version__)
print("CUDA runtime:", torch.version.cuda)
print("CUDA available:", cuda_available)
if cuda_available:
    print("GPU:", torch.cuda.get_device_name(0))
else:
    print("[WARN] Running in CPU mode. Separation will be significantly slower.")
PY

echo "--> Verifying vocal-separator environment..."
"$SEPARATOR" --env_info

echo "--> Setup complete. You can now run the separation command."
