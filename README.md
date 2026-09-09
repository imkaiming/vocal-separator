# Mel-Band RoFormer vocal and instrumental separation

A local Windows workflow for separating a mixed song into vocal and instrumental stems.

It includes:

- `setup.sh` to build and verify a GPU-accelerated or CPU-only Python environment.
- `vocal-separator.sh` to run the separation with suitable defaults.
- Automatic model downloading on the first separation.

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

The environment, downloaded models, input recordings and generated outputs are excluded from Git.

Always preserve the original recording. Source separation is not perfectly reversible.

## Dependencies

The setup script expects:

- Windows with Git Bash
- Python 3.12
- FFmpeg available on `PATH`
- An NVIDIA driver with CUDA support (optional, for acceleration)

It installs and configures:

- `audio-separator` 0.47.0, with its GPU extra when CUDA is usable
- PyTorch 2.14.0 and Torchvision 0.29.0, using CUDA 13.0 when available
- `audioread` 3.1.0
- `diffq-fixed` 0.2.4 and the remaining Audio Separator dependencies

Python 3.12 is intentional. `diffq-fixed` 0.2.4 provides a Windows wheel for Python 3.12 but not Python 3.14.

## Quick start

### 1. Install Python 3.12 if needed

```bash
winget install --exact --id Python.Python.3.12
```

verify the installation:

```bash
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

### 5. Run

```bash
./vocal-separator.sh "input/test.wav"
```

On the first run, Audio Separator automatically downloads the model checkpoint and its matching configuration into `models`.

## Use cases

Additional arguments can be placed after the input filename:

```bash
./vocal-separator.sh "input/test.wav" --mdxc_overlap 4
```

Examples:

```bash
# Use a different segment size
./vocal-separator.sh "input/test.wav" --mdxc_segment_size 128

# Export as FLAC
./vocal-separator.sh "input/test.wav" --output_format FLAC

# Export as MP3
./vocal-separator.sh "input/test.wav" \
  --output_format MP3 \
  --output_bitrate 320k

# Write results to another directory
./vocal-separator.sh "input/test.wav" \
  --output_dir "/c/path/to/Separated"
```

Run the underlying help command to see every available option:

```bash
venv/Scripts/audio-separator.exe --help
```

## Wrapper defaults

`vocal-separator.sh` configures:

```text
Model:        mel_band_roformer_instrumental_becruily.ckpt
Output:       WAV
Precision:    native FP16
Segment size: 128
Batch size:   1
Overlap:      2
Model folder: models/
Output folder: output/
```

The wrapper does not use `--single_stem`, so both vocal and instrumental stems are generated.

## Manual model download

To download the model without processing audio:

```bash
venv/Scripts/audio-separator.exe \
  --model_filename mel_band_roformer_instrumental_becruily.ckpt \
  --model_file_dir "$PWD/models" \
  --download_model_only
```

## Verify the environment manually

Check PyTorch and CUDA:

```bash
venv/Scripts/python.exe -c "import torch; print('PyTorch:', torch.__version__); print('CUDA runtime:', torch.version.cuda); print('CUDA available:', torch.cuda.is_available()); print(torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'GPU not detected')"
```

`CUDA available: True` means GPU acceleration is active. `False` means the project will run on the CPU.

Check the complete Audio Separator environment:

```bash
venv/Scripts/audio-separator.exe --env_info
```

The output should report:

- Python 3.12;
- a CUDA-enabled PyTorch build when an NVIDIA GPU is available, or CPU PyTorch otherwise;
- FFmpeg installed;
- CUDA available in Torch and the ONNX Runtime CUDA execution provider available when GPU acceleration is active.

Use `venv/Scripts/python.exe` or `venv/Scripts/audio-separator.exe` when working inside this project. The Windows `py` launcher can bypass the virtual environment.
