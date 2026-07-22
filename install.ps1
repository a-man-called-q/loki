# Installs loki by cloning the repo, building it with build.ps1, and
# copying the resulting binary onto your PATH. Run directly:
#
#   irm https://raw.githubusercontent.com/a-man-called-q/loki/main/install.ps1 | iex
#
$ErrorActionPreference = "Stop"

$RepoUrl = "https://github.com/a-man-called-q/loki.git"
$SrcDir = if ($env:LOKI_SRC_DIR) { $env:LOKI_SRC_DIR } else { Join-Path $env:LOCALAPPDATA "loki\src" }
$BinDir = if ($env:LOKI_BIN_DIR) { $env:LOKI_BIN_DIR } else { Join-Path $env:LOCALAPPDATA "loki\bin" }

function Info($msg) { Write-Host "==> $msg" -ForegroundColor Green }
function Fail($msg) { Write-Host "error: $msg" -ForegroundColor Red; exit 1 }

if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Fail "git not found on PATH -- install it from https://git-scm.com/downloads (e.g. 'winget install Git.Git')" }
if (-not (Get-Command odin -ErrorAction SilentlyContinue)) { Fail "odin not found on PATH -- install it from https://odin-lang.org/docs/install/" }

if (-not $env:LOKI_BIN_DIR -and [Environment]::UserInteractive) {
    $reply = Read-Host "Install loki to [$BinDir]"
    if ($reply) { $BinDir = $reply }
}

if (Test-Path (Join-Path $SrcDir ".git")) {
    Info "updating existing checkout in $SrcDir"
    git -C $SrcDir pull --ff-only
} else {
    Info "cloning loki into $SrcDir"
    git clone --depth 1 $RepoUrl $SrcDir
}

Info "building loki"
Push-Location $SrcDir
try {
    & ./build.ps1
    if ($LASTEXITCODE -ne 0) { Fail "build failed" }
} finally {
    Pop-Location
}

New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
Copy-Item (Join-Path $SrcDir "bin\loki.exe") (Join-Path $BinDir "loki.exe") -Force

Info "installed to $BinDir\loki.exe"

$pathEntries = $env:Path -split ";"
if ($pathEntries -notcontains $BinDir) {
    Write-Host ""
    Write-Host "heads up: $BinDir is not on your PATH." -ForegroundColor Yellow
    Write-Host "Add it for this session with:"
    Write-Host ""
    Write-Host "  `$env:Path = `"$BinDir;`$env:Path`""
    Write-Host ""
    Write-Host "Or add it permanently via Settings > System > Environment Variables."
}

Info "run 'loki doctor' to confirm the environment checks out"
