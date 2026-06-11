# llamacpp-win-cuda-service-scripts

PowerShell scripts for keeping a local Windows CUDA build of
[llama.cpp](https://github.com/ggml-org/llama.cpp) up to date and running as a
local `llama-server` instance.

This repository is intentionally script-only. It does not include downloaded
llama.cpp binaries, CUDA runtime files, model files, logs, runtime state, or
private tokens.

## What It Does

- Checks the latest `ggml-org/llama.cpp` release on GitHub.
- Selects the newest matching Windows x64 CUDA release asset pair.
- Downloads and verifies release archives when GitHub provides SHA-256 digests.
- Installs the selected build into a versioned local directory.
- Switches `llama-current` to the active install directory.
- Starts, stops, and checks a local `llama-server`.
- Keeps a small number of previous installs and cached archives for rollback.

## Requirements

- Windows PowerShell.
- Windows with an NVIDIA GPU and compatible driver for the selected CUDA build.
- Network access to GitHub releases.
- Local GGUF model files.
- Optional: GitHub CLI or a `GITHUB_TOKEN`/`GH_TOKEN` environment variable to
  avoid unauthenticated GitHub API rate limits.

## Quick Start

1. Clone this repository.
2. Copy `llama-config/models.example.ini` to `llama-config/models.ini`.
3. Edit `llama-config/models.ini` and point `model = ...` entries to your local
   GGUF files.
4. Optional: set `GITHUB_TOKEN` or `GH_TOKEN` in your environment. If you prefer
   a local file, copy `llama-config/github-token.example.txt` to
   `llama-config/github-token.txt` and put the token there.
5. Run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\llama-scripts\update-llamacpp-cuda13.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\llama-scripts\start-llamacpp-server.ps1
```

The default server URL is `http://127.0.0.1:8080`.

## Scripts

- `llama-scripts/update-llamacpp-cuda13.ps1`: download, install, switch, restart,
  and clean up old local builds.
- `llama-scripts/start-llamacpp-server.ps1`: start `llama-server` with the local
  models preset.
- `llama-scripts/stop-llamacpp-server.ps1`: unload loaded models and stop the
  server process.
- `llama-scripts/check-llamacpp-version.ps1`: compare the local active build
  with the latest upstream release.
- `llama-scripts/register-update-task-run-logged-off.ps1`: register a Windows
  scheduled task for periodic updates.
- `llama-scripts/test-llama-scripts.ps1`: run lightweight script tests.

## Configuration

The private configuration file is `llama-config/models.ini`. It is ignored by
Git because it usually contains machine-specific model paths.

The private token file is `llama-config/github-token.txt`. It is also ignored by
Git. Prefer environment variables when possible:

```powershell
$env:GITHUB_TOKEN = "your_token_here"
```

## Repository Hygiene

The `.gitignore` excludes:

- `llama-config/github-token.txt`
- `llama-config/models.ini`
- downloaded llama.cpp/CUDA binaries
- download cache archives
- logs and runtime pid files
- the `llama-current` junction

Do not commit model files, CUDA DLLs, release ZIP files, logs, or local tokens.

## License

The scripts in this repository are released under the MIT License. Downloaded
llama.cpp artifacts remain under their upstream licenses, and CUDA runtime
components are governed by NVIDIA's license terms.
