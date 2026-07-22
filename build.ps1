#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"

Set-Location (Split-Path -Parent $MyInvocation.MyCommand.Path)

New-Item -ItemType Directory -Force -Path "bin" | Out-Null

odin build apps/loki `
  -collection:local=packages/local `
  -collection:deps=packages/vendor `
  -out:bin/loki.exe

if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "built bin/loki.exe"
