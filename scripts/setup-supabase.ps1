# ═══════════════════════════════════════════════════════════
# TalkGram · автоматическая настройка Supabase (одна команда)
# ─────────────────────────────────────────────────────────────
# 1. Создайте аккаунт: https://supabase.com (GitHub или почта)
# 2. Токен: https://supabase.com/dashboard/account/tokens →
#    "Generate new token" → скопируйте
# 3. Запустите (в PowerShell):
#    powershell -ExecutionPolicy Bypass -File .\scripts\setup-supabase.ps1 -Token "ТОКЕН"
#
# Скрипт сам: создаст организацию → проект (БД) → применит
# supabase/migrations/0001_init.sql → получит anon-ключ →
# запишет его в config.js. Останется только запушить.
# ═══════════════════════════════════════════════════════════
param(
  [Parameter(Mandatory = $true)][string]$Token,
  [string]$ProjectName = "talkgram",
  [string]$Region = "eu-central-1"
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$Npx = (Get-Command npx.cmd -ErrorAction SilentlyContinue).Source
if (-not $Npx) { $Npx = "npx.cmd" }
$Root = Split-Path -Parent $PSScriptRoot

function Step($msg){ Write-Host "`n==> $msg" -ForegroundColor Cyan }

# 1. Вход
Step "Вход в Supabase..."
& $Npx -y supabase login --token $Token
if ($LASTEXITCODE -ne 0) { throw "Не удалось войти. Проверьте токен." }

# 2. Организация (создаём, если нет)
Step "Организация..."
$orgs = (& $Npx -y supabase orgs list --output json 2>$null | ConvertFrom-Json)
if (-not $orgs) {
  $orgOut = (& $Npx -y supabase orgs create "TalkGram") -join "`n"
  $orgId = [regex]::Match($orgOut, "([a-z0-9]{20,})").Groups[1].Value
  if (-not $orgId) { throw "Не удалось создать организацию: $orgOut" }
  Write-Host "Создана организация: $orgId"
} else {
  $orgId = $orgs[0].id
  Write-Host "Использую организацию: $($orgs[0].name) ($orgId)"
}

# 3. Проект (БД)
Step "Создание проекта '$ProjectName' ($Region)..."
$dbPass = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 24 | ForEach-Object { [char]$_ })
$projOut = (& $Npx -y supabase projects create $ProjectName --org-id $orgId --db-password $dbPass --region $Region) -join "`n"
$ref = [regex]::Match($projOut, "https://([a-z0-9]+)\.supabase\.co").Groups[1].Value
if (-not $ref) { $ref = [regex]::Match($projOut, "Created a new project (\w+)").Groups[1].Value }
if (-not $ref) { throw "Не удалось распознать реф проекта: $projOut" }
Write-Host "Проект: $ref"

# 4. Линковка + миграции (проект поднимается 1–2 минуты — ретраим)
Step "Применение схемы (может занять 1–2 минуты)..."
Push-Location $Root
try {
  $done = $false
  for ($i = 1; $i -le 12; $i++) {
    & $Npx -y supabase link --project-ref $ref -p $dbPass 2>&1 | Out-Null
    & $Npx -y supabase db push --linked -p $dbPass --yes 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { $done = $true; break }
    Write-Host "База ещё поднимается... попытка $i/12 (жду 15 c)"
    Start-Sleep -Seconds 15
  }
  if (-not $done) { throw "Не удалось применить миграции за отведённое время." }
} finally { Pop-Location }

# 5. Ключи API
Step "Ключи API..."
$keys = (& $Npx -y supabase projects api-keys --project-ref $ref --output json 2>$null | ConvertFrom-Json)
$anon = $keys | Where-Object { $_.name -eq "anon" } | Select-Object -First 1
if (-not $anon) { throw "anon-ключ не найден: $($keys | Out-String)" }
$url = "https://$ref.supabase.co"

# 6. config.js
Step "Обновляю config.js..."
$cfg = @"
/* TalkGram · конфигурация бэкенда (заполнена автоматически: scripts/setup-supabase.ps1) */
window.SUPABASE_CONFIG = {
  url: '$url',
  anonKey: '$($anon.api_key)',
  /* TODO: TURN-серверы для звонков между разными сетями:
     { urls: 'turn:relay.metered.ca:80', username: '...', credential: '...' } */
  turnServers: []
};
"@
[System.IO.File]::WriteAllText((Join-Path $Root "config.js"), $cfg, (New-Object System.Text.UTF8Encoding($false)))

# 7. Пароль БД — локально (в .gitignore), пригодится для будущих миграций
[System.IO.File]::WriteAllText((Join-Path $Root "supabase\.db-password"), $dbPass, (New-Object System.Text.UTF8Encoding($false)))

Write-Host "`n════════════════════════════════════════════" -ForegroundColor Green
Write-Host "ГОТОВО!" -ForegroundColor Green
Write-Host "URL проекта : $url"
Write-Host "anon key    : $($anon.api_key)"
Write-Host "Пароль БД   : supabase/.db-password (не коммитится)"
Write-Host "Панель      : https://supabase.com/dashboard/project/$ref"
Write-Host "Дальше: git add config.js; git commit -m `"supabase: подключение`"; git push"
