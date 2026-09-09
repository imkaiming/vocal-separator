# Vocal Separator

A thin local Windows tool for splitting a song into vocal and instrumental stems.

It includes:

- `setup.sh` to build and verify a GPU-accelerated or CPU-only Python environment
- `vocal-separator.sh` to run separation with sensible defaults
- Automatic model download on the first run

## Project origins

This wrapper is built around third-party open-source work:

- [python-audio-separator](https://github.com/nomadkaraoke/python-audio-separator) provides the command-line runner and model management. Its separation code is derived primarily from [Ultimate Vocal Remover](https://github.com/Anjok07/ultimatevocalremovergui) (UVR).
- [Mel-Band RoFormer](https://arxiv.org/abs/2310.01809) is the source-separation architecture described by Ju-Chiang Wang, Wei-Tsung Lu, and Minz Won.
- [Mel-Band RoFormer Instrumental by Becruily](https://huggingface.co/becruily/mel-band-roformer-instrumental) provides the checkpoint used here: `mel_band_roformer_instrumental_becruily.ckpt`.

The upstream projects and model retain their respective licenses and attribution requirements.

## Folder layout

```text
vocal-separator/
├── input/                 Source audio
├── models/                Downloaded checkpoints and configurations
├── output/                Generated vocal and instrumental stems
├── venv/                  Project-local Python environment
├── vocal-separator.sh     Separation wrapper
├── setup.sh               Environment setup
├── .gitignore
└── README.md
```

## Prerequisites

- Windows + Bash
- Python 3.12
- FFmpeg available on `PATH`
- NVIDIA GPU + recent driver (optional, strongly recommended)

Python 3.12 is required because `diffq-fixed` provides a Windows wheel for 3.12 but not for 3.14.

## What setup installs

- `audio-separator` 0.47.0 (GPU extra when CUDA is available)
- PyTorch + Torchvision (CUDA build when possible, otherwise CPU)
- `audioread` and remaining Audio Separator dependencies

Exact package versions are pinned in `setup.sh`.

GPU is strongly preferred. CPU mode works but is much slower.

## Quick start

### 1. Install Python 3.12 if needed

```bash
winget install --exact --id Python.Python.3.12
py -3.12 --version
```

### 2. Make the scripts executable

```bash
chmod +x setup.sh vocal-separator.sh
```

### 3. Build the environment

```bash
./setup.sh
```

### 4. Add your audio

Place a file in `input/`, for example:

```text
input/test.wav
```

WAV is preferred for quality. Common formats such as MP3 are also supported. The original file is never modified.

### 5. Run the separator

```bash
./vocal-separator.sh "input/test.wav"
```

On the first run the model checkpoint is downloaded into `models/`.

Vocal and instrumental stems are written to `output/`. Some bleed or artifacts can remain, especially on dense mixes.

## Common options

Extra arguments can be passed after the input file:

```bash
./vocal-separator.sh "input/test.wav" --mdxc_overlap 4
```

Examples:

```bash
# Lower VRAM usage
./vocal-separator.sh "input/test.wav" --mdxc_segment_size 64

# Export as FLAC
./vocal-separator.sh "input/test.wav" --output_format FLAC

# Export as MP3
./vocal-separator.sh "input/test.wav" \
  --output_format MP3 \
  --output_bitrate 320k

# Custom output directory
./vocal-separator.sh "input/test.wav" \
  --output_dir "/c/path/to/Separated"
```

Full option list:

```bash
venv/Scripts/audio-separator.exe --help
```

## Wrapper defaults

```text
Model:         mel_band_roformer_instrumental_becruily.ckpt
Output format: WAV
Precision:     native FP16
Segment size:  128
Batch size:    1
Overlap:       2
Model folder:  models/
Output folder: output/
```

Both vocal and instrumental stems are generated.

## Manual model download

```bash
venv/Scripts/audio-separator.exe \
  --model_filename mel_band_roformer_instrumental_becruily.ckpt \
  --model_file_dir "$PWD/models" \
  --download_model_only
```

## Verify the environment

```bash
venv/Scripts/python.exe -c "import torch; print('PyTorch:', torch.__version__); print('CUDA available:', torch.cuda.is_available()); print(torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'CPU mode')"
```

```bash
venv/Scripts/audio-separator.exe --env_info
```

Use `venv/Scripts/python.exe` and `venv/Scripts/audio-separator.exe` inside this project. The Windows `py` launcher can bypass the virtual environment.

## Troubleshooting

**CUDA out of memory**  
Reduce segment size:

```bash
./vocal-separator.sh "input/test.wav" --mdxc_segment_size 64
```

**Runs very slowly**  
You are likely on CPU. GPU acceleration is strongly recommended.

## License

This repository's wrapper scripts are provided as-is for personal use.