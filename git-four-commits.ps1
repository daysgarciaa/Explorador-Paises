#Requires -Version 5.1
<#
.SYNOPSIS
    Crea 4 commits descriptivos para subir el proyecto a GitHub.
.USAGE
    Desde la raíz del repo (PowerShell):
      .\git-four-commits.ps1
    Si aún no hay repo:
      git init
      .\git-four-commits.ps1
#>
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "Git no está en PATH. Instala Git for Windows y vuelve a abrir la terminal."
    exit 1
}

if (-not (git config user.name) -or -not (git config user.email)) {
    Write-Error @"
Configura tu identidad de Git antes de continuar:
  git config --global user.name "Tu Nombre"
  git config --global user.email "tu@email.com"
"@
    exit 1
}

if (-not (Test-Path .git)) {
    Write-Host "Inicializando repositorio..." -ForegroundColor Cyan
    git init
    git branch -M main
}

function Invoke-CommitGroup {
    param(
        [string[]]$Paths,
        [string]$Message
    )
    $existing = $Paths | Where-Object { Test-Path $_ }
    if (-not $existing) {
        Write-Warning "No hay archivos para: $($Paths -join ', ')"
        return
    }
    git add -- $existing
    $staged = git diff --cached --name-only
    if (-not $staged) {
        Write-Host "Sin cambios nuevos para: $Message" -ForegroundColor Yellow
        return
    }
    git commit -m $Message
    Write-Host "OK: $Message" -ForegroundColor Green
}

# 1 — Aplicación Python y dependencias
Invoke-CommitGroup @(
    "app.py",
    "requirements.txt"
) "feat(cli): World Explorer con RestCountries, Open-Meteo y manejo robusto de errores"

# 2 — Docker y automatización
Invoke-CommitGroup @(
    "Dockerfile",
    "build.sh"
) "feat(docker): Dockerfile y build.sh con build, run y generación de output.txt"

# 3 — Documentación del repositorio e ignores
Invoke-CommitGroup @(
    "README.md",
    ".gitignore",
    "output.txt",
    "git-four-commits.ps1"
) "docs: README con narrativa, env vars, Docker/Jenkins y salida de ejemplo"

# 4 — Evidencias y plantillas Jenkins
Invoke-CommitGroup @(
    "evidencias/jenkins/README.md",
    "evidencias/jenkins/SamplePipeline-inline.groovy",
    "evidencias/jenkins/BuildAppJob-notas.txt",
    "evidencias/jenkins/bitacora-errores.md"
) "docs(jenkins): pipeline SamplePipeline, notas BuildAppJob y plantilla de bitácora"

Write-Host "`nHistorial reciente:" -ForegroundColor Cyan
git log --oneline -5

Write-Host "`nSiguiente paso (remoto GitHub):" -ForegroundColor Cyan
Write-Host "  git remote add origin https://github.com/<usuario>/<repo>.git"
Write-Host "  git push -u origin main"
