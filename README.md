# Mel-Band RoFormer vocal and instrumental separation

This project provides a local Windows workflow for separating a mixed song into vocal and instrumental stems.

It includes:

- `setup.sh` to build and verify the Python/CUDA environment.
- `audio-separator.sh` to run the separation with suitable defaults.
- Automatic model downloading on the first separation.

## Project origins

This wrapper is built around third-party open-source work:

- [python-audio-separator](https://github.com/nomadkaraoke/python-audio-separator) provides the command-line runner and model management. Its separation code is derived primarily from [Ultimate Vocal Remover](https://github.com/Anjok07/ultimatevocalremovergui) (UVR).
- [Mel-Band RoFormer](https://arxiv.org/abs/2310.01809) is the source-separation architecture described by Ju-Chiang Wang, Wei-Tsung Lu, and Minz Won.
- [Mel-Band RoFormer Instrumental by Becruily](https://huggingface.co/becruily/mel-band-roformer-instrumental) provides the checkpoint used here: `mel_band_roformer_instrumental_becruily.ckpt`.

The upstream projects and model retain their respective licenses and attribution requirements.

## Folder layout

```text
audio-separator/
├── input/                 Source audio
├── models/                Downloaded checkpoints and configurations
├── output/                Generated vocal and instrumental stems
├── venv/                  Project-local Python environment
├── audio-separator.sh     Separation wrapper
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
- An NVIDIA driver with CUDA support
- Internet access during setup and the first separation

It installs and configures:

- `audio-separator[gpu]` 0.47.0
- PyTorch 2.14.0 with CUDA 13.0
- Torchvision 0.29.0 with CUDA 13.0
- `audioread` 3.1.0
- `diffq-fixed` 0.2.4 and the remaining Audio Separator dependencies

Python 3.12 is intentional. `diffq-fixed` 0.2.4 provides a Windows wheel for Python 3.12 but not Python 3.14.

## Quick start

Open Git Bash in the project directory.

### 1. Install Python 3.12 if needed

```bash
winget install --exact --id Python.Python.3.12
```

Restart Git Bash, then verify the installation:

```bash
py -3.12 --version
```

### 2. Make the scripts executable

```bash
chmod +x setup.sh audio-separator.sh
```

### 3. Build the environment

```bash
./setup.sh
```

The setup script:

1. Verifies Python 3.12 and FFmpeg.
2. Creates the local `venv`.
3. Installs Audio Separator and its dependencies.
4. Replaces CPU-only PyTorch with the CUDA build.
5. Checks the dependency tree.
6. Verifies that CUDA is available.
7. Verifies the complete Audio Separator environment.
8. Creates `input`, `output` and `models`.

Setup stops with an error if an existing environment uses the wrong Python version or if PyTorch cannot access CUDA. It does not automatically delete an existing environment.

### 4. Add an input file

Place a mixed recording in `input`, for example:

```text
input/test.wav
```

WAV is recommended for the best available source quality, although Audio Separator supports other common audio formats.

For the first test, use a short representative section containing vocals, instruments and a quieter passage. This makes bleed and separation artifacts easier to evaluate.

### 5. Run the separation

```bash
./audio-separator.sh "input/test.wav"
```

On the first run, Audio Separator automatically downloads the model checkpoint and its matching configuration into `models`. The checkpoint is approximately 913 MB.

Two files are written to `output`:

- the isolated vocal stem;
- the isolated instrumental stem.

## Separating a file outside the project

You can provide any valid file path:

```bash
./audio-separator.sh "/c/Users/kai/Music/My Song.wav"
```

Always quote paths containing spaces or shell metacharacters.

## Additional options

Additional Audio Separator arguments can be placed after the input filename:

```bash
./audio-separator.sh "input/test.wav" --mdxc_overlap 4
```

Examples:

```bash
# Use a different segment size
./audio-separator.sh "input/test.wav" --mdxc_segment_size 128

# Export as FLAC
./audio-separator.sh "input/test.wav" --output_format FLAC

# Export as MP3
./audio-separator.sh "input/test.wav" \
  --output_format MP3 \
  --output_bitrate 320k

# Write results to another directory
./audio-separator.sh "input/test.wav" \
  --output_dir "/c/Users/kai/Music/Separated"
```

For ordinary value options, arguments supplied on the command line override the wrapper defaults because they are forwarded last.

Run the underlying help command to see every available option:

```bash
venv/Scripts/audio-separator.exe --help
```

## Wrapper defaults

`audio-separator.sh` configures:

```text
Model:        mel_band_roformer_instrumental_becruily.ckpt
Output:       WAV
Precision:    native FP16
Segment size: 64
Batch size:   1
Overlap:      2
Model folder: models/
Output folder: output/
```

The wrapper does not use `--single_stem`, so both vocal and instrumental stems are generated.

## Manual model download

The run script downloads the model automatically. To download it without processing audio:

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

`CUDA available` must report `True`.

Check the complete Audio Separator environment:

```bash
venv/Scripts/audio-separator.exe --env_info
```

The output should report:

- Python 3.12;
- a CUDA-enabled PyTorch build;
- FFmpeg installed;
- CUDA available in Torch;
- the ONNX Runtime CUDA execution provider available.

Use `venv/Scripts/python.exe` or `venv/Scripts/audio-separator.exe` when working inside this project. The Windows `py` launcher can bypass the virtual environment.

## Troubleshooting

### Existing environment uses the wrong Python version

Preserve the existing environment by renaming it:

```bash
mv venv venv-incompatible
./setup.sh
```

Do not overwrite an environment containing files you need.

### `diffq-fixed` fails with `bitpack.pyx doesn't match any files`

The environment was probably created with Python 3.14.

Rename it and rebuild with Python 3.12:

```bash
mv venv venv-incompatible
py -3.12 -m venv venv
./setup.sh
```

### `No module named 'audioread'`

Install the missing package inside the project environment:

```bash
venv/Scripts/python.exe -m pip install audioread==3.1.0
```

### `CUDA available: False`

Confirm that the command uses the project environment:

```bash
venv/Scripts/python.exe -c "import torch; print(torch.__version__); print(torch.cuda.is_available())"
```

A PyTorch version ending in `+cpu` is CPU-only. Run `setup.sh` after preserving or correcting the existing environment.

### CUDA out of memory

Close other applications using hardware acceleration and reduce the segment size:

```bash
./audio-separator.sh "input/test.wav" --mdxc_segment_size 32
```

Keep the batch size at `1` and continue using native FP16.

Smaller segments reduce memory use but can increase processing time and separation artifacts.

### Input file not found

Paths are resolved from the directory where the wrapper was launched. Check the path and keep it quoted:

```bash
./audio-separator.sh "/c/Users/kai/Music/My Song.wav"
```

### Separation artifacts

Reverb, delay, backing vocals and instruments sharing frequencies with the voice can cause bleed or artifacts in either stem.

Evaluate both outputs against the preserved source before using them in a final production.