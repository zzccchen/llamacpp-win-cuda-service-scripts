# llamacpp-win-cuda-service-scripts

Windows PowerShell 脚本，用于自动下载、更新、切换并运行本地
[llama.cpp](https://github.com/ggml-org/llama.cpp) Windows CUDA 版
`llama-server`。

PowerShell scripts for downloading, updating, switching, and running a local
Windows CUDA build of [llama.cpp](https://github.com/ggml-org/llama.cpp) as a
`llama-server` instance.

本仓库只包含脚本和示例配置，不包含下载后的 llama.cpp 二进制、CUDA 运行时、
模型文件、日志、运行状态或私人 token。

This repository is intentionally script-only. It does not include downloaded
llama.cpp binaries, CUDA runtime files, model files, logs, runtime state, or
private tokens.

## 功能 / What It Does

- 检查 `ggml-org/llama.cpp` 在 GitHub 上的最新 release。 / Checks the latest
  `ggml-org/llama.cpp` release on GitHub.
- 选择最新匹配的 Windows x64 CUDA 主程序包和 CUDA runtime 包。 / Selects the
  newest matching Windows x64 CUDA release asset pair.
- 在 GitHub 提供 SHA-256 digest 时，下载并校验 release 压缩包。 / Downloads and
  verifies release archives when GitHub provides SHA-256 digests.
- 将选中的版本安装到本地带版本号的目录。 / Installs the selected build into a
  versioned local directory.
- 将 `llama-current` 切换到当前启用的安装目录。 / Switches `llama-current` to
  the active install directory.
- 启动、停止并检查本地 `llama-server`。 / Starts, stops, and checks a local
  `llama-server`.
- 保留少量旧版本和缓存压缩包，方便回滚。 / Keeps a small number of previous
  installs and cached archives for rollback.

## 环境要求 / Requirements

- Windows PowerShell。 / Windows PowerShell.
- Windows 系统，NVIDIA GPU，以及兼容所选 CUDA build 的驱动。 / Windows with an
  NVIDIA GPU and a compatible driver for the selected CUDA build.
- 能访问 GitHub releases 的网络环境。 / Network access to GitHub releases.
- 本地 GGUF 模型文件。 / Local GGUF model files.
- 可选：GitHub CLI，或 `GITHUB_TOKEN`/`GH_TOKEN` 环境变量，用于避免 GitHub API
  未认证请求限流。 / Optional: GitHub CLI or a `GITHUB_TOKEN`/`GH_TOKEN`
  environment variable to avoid unauthenticated GitHub API rate limits.

## 快速开始 / Quick Start

1. 克隆本仓库。 / Clone this repository.
2. 复制 `llama-config/models.example.ini` 为 `llama-config/models.ini`。 / Copy
   `llama-config/models.example.ini` to `llama-config/models.ini`.
3. 编辑 `llama-config/models.ini`，把 `model = ...` 指向你的本地 GGUF 文件。 /
   Edit `llama-config/models.ini` and point `model = ...` entries to your local
   GGUF files.
4. 可选：设置 `GITHUB_TOKEN` 或 `GH_TOKEN` 环境变量。如果你更想用本地文件，可以
   复制 `llama-config/github-token.example.txt` 为
   `llama-config/github-token.txt`，再把 token 写进去。 / Optional: set
   `GITHUB_TOKEN` or `GH_TOKEN` in your environment. If you prefer a local file,
   copy `llama-config/github-token.example.txt` to
   `llama-config/github-token.txt` and put the token there.
5. 运行： / Run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\llama-scripts\update-llamacpp-cuda13.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\llama-scripts\start-llamacpp-server.ps1
```

默认服务地址是 `http://127.0.0.1:8080`。

The default server URL is `http://127.0.0.1:8080`.

## 脚本 / Scripts

- `llama-scripts/update-llamacpp-cuda13.ps1`：下载、安装、切换、重启，并清理旧
  版本。 / Downloads, installs, switches, restarts, and cleans up old local
  builds.
- `llama-scripts/start-llamacpp-server.ps1`：使用本地 models preset 启动
  `llama-server`。 / Starts `llama-server` with the local models preset.
- `llama-scripts/stop-llamacpp-server.ps1`：卸载已加载模型并停止 server 进程。 /
  Unloads loaded models and stops the server process.
- `llama-scripts/check-llamacpp-version.ps1`：比较本地启用版本和上游最新 release。
  / Compares the local active build with the latest upstream release.
- `llama-scripts/register-update-task-run-logged-off.ps1`：注册周期更新的 Windows
  计划任务。 / Registers a Windows scheduled task for periodic updates.
- `llama-scripts/test-llama-scripts.ps1`：运行轻量脚本测试。 / Runs lightweight
  script tests.

## 配置 / Configuration

私有配置文件是 `llama-config/models.ini`。它通常包含本机模型路径，所以已被 Git
忽略。

The private configuration file is `llama-config/models.ini`. It is ignored by
Git because it usually contains machine-specific model paths.

私有 token 文件是 `llama-config/github-token.txt`，也已被 Git 忽略。更推荐使用
环境变量：

The private token file is `llama-config/github-token.txt`. It is also ignored by
Git. Prefer environment variables when possible:

```powershell
$env:GITHUB_TOKEN = "your_token_here"
```

## 仓库安全 / Repository Hygiene

`.gitignore` 会排除：

The `.gitignore` excludes:

- `llama-config/github-token.txt`
- `llama-config/models.ini`
- 下载后的 llama.cpp/CUDA 二进制文件。 / downloaded llama.cpp/CUDA binaries.
- 下载缓存压缩包。 / download cache archives.
- 日志和运行时 pid 文件。 / logs and runtime pid files.
- `llama-current` junction。 / the `llama-current` junction.

不要提交模型文件、CUDA DLL、release ZIP、日志或本地 token。

Do not commit model files, CUDA DLLs, release ZIP files, logs, or local tokens.

## 许可证 / License

本仓库中的脚本使用 MIT License 发布。下载后的 llama.cpp artifacts 仍遵循其上游
许可证，CUDA runtime 组件受 NVIDIA 许可条款约束。

The scripts in this repository are released under the MIT License. Downloaded
llama.cpp artifacts remain under their upstream licenses, and CUDA runtime
components are governed by NVIDIA's license terms.
