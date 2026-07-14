# Recreates this machine's Claude Code environment on a new Windows machine:
# - cc / ccd / ccr PowerShell aliases
# - Notification/Stop sound hook + PreToolUse dangerous-command block hook
# - GPTaku marketplace + plugins (show-me-the-prd, skillers-suda, kkirikkiri,
#   insane-search, insane-research, insane-harness, insane-design)
#
# Safe to re-run (idempotent). Run from a normal PowerShell window:
#   .\scripts\setup-env.ps1

$ErrorActionPreference = "Stop"

# --- 1. cc / ccd / ccr aliases -------------------------------------------
$profileDir = Split-Path $PROFILE -Parent
if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Force -Path $profileDir | Out-Null }
if (-not (Test-Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE | Out-Null }

$marker = "# --- GPTers Claude Code study: cc/ccd/ccr aliases ---"
$profileContent = Get-Content -Path $PROFILE -Raw -ErrorAction SilentlyContinue
if ($profileContent -notmatch [regex]::Escape($marker)) {
    $block = @"

$marker
function cc { claude @args }
function ccd { claude --dangerously-skip-permissions @args }
function ccr { claude --resume --dangerously-skip-permissions @args }
# --- end GPTers Claude Code study aliases ---
"@
    Add-Content -Path $PROFILE -Value $block -Encoding utf8
    Write-Output "[1/4] cc/ccd/ccr aliases added to $PROFILE"
} else {
    Write-Output "[1/4] cc/ccd/ccr aliases already present, skipped"
}

# --- 2. Hook scripts -------------------------------------------------------
$hooksDir = "$HOME\.claude\hooks"
if (-not (Test-Path $hooksDir)) { New-Item -ItemType Directory -Force -Path $hooksDir | Out-Null }

$notifyScript = @'
param(
    [string]$Message = "Claude 알림",
    [int]$Tone = 880
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[console]::beep($Tone, 250)
$out = @{ systemMessage = $Message } | ConvertTo-Json -Compress
[Console]::Out.Write($out)
'@

$blockScript = @'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$raw = [Console]::In.ReadToEnd()
if (-not $raw) { exit 0 }

try {
    $data = $raw | ConvertFrom-Json
} catch {
    exit 0
}

$cmd = $data.tool_input.command
if (-not $cmd) { exit 0 }

if ($cmd -match 'rm\s+-rf' -or $cmd -match 'git\s+reset\s+--hard' -or $cmd -match '(^|[\s;&|])sudo([\s;&|]|$)') {
    $result = @{
        hookSpecificOutput = @{
            hookEventName = 'PreToolUse'
            permissionDecision = 'deny'
            permissionDecisionReason = "위험 명령이 감지되어 차단되었습니다: $cmd"
        }
    }
    [Console]::Out.Write(($result | ConvertTo-Json -Compress -Depth 5))
}
'@

$utf8bom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText("$hooksDir\notify.ps1", $notifyScript, $utf8bom)
[System.IO.File]::WriteAllText("$hooksDir\block-dangerous.ps1", $blockScript, $utf8bom)
Write-Output "[2/4] hook scripts written to $hooksDir"

# --- 3. Merge hooks + env into ~/.claude/settings.json ---------------------
# Note: this replaces any existing Notification/Stop/PreToolUse entries by
# the same name. Other event types and top-level settings are preserved.
$settingsPath = "$HOME\.claude\settings.json"
if (Test-Path $settingsPath) {
    $settings = Get-Content $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not $settings) { $settings = New-Object PSObject }
} else {
    $settings = New-Object PSObject
}

if (-not ($settings.PSObject.Properties.Name -contains "env")) {
    $settings | Add-Member -NotePropertyName env -NotePropertyValue (New-Object PSObject)
}
$settings.env | Add-Member -NotePropertyName "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" -NotePropertyValue "1" -Force

if (-not ($settings.PSObject.Properties.Name -contains "hooks")) {
    $settings | Add-Member -NotePropertyName hooks -NotePropertyValue (New-Object PSObject)
}

$notifyCmd = "powershell -NoProfile -ExecutionPolicy Bypass -File `"$hooksDir\notify.ps1`" -Message `"Claude 확인이 필요합니다.`" -Tone 880"
$stopCmd   = "powershell -NoProfile -ExecutionPolicy Bypass -File `"$hooksDir\notify.ps1`" -Message `"Claude 작업이 끝났습니다.`" -Tone 600"
$blockCmd  = "powershell -NoProfile -ExecutionPolicy Bypass -File `"$hooksDir\block-dangerous.ps1`""

$settings.hooks | Add-Member -NotePropertyName "Notification" -NotePropertyValue @(
    @{ hooks = @(@{ type = "command"; command = $notifyCmd; timeout = 10 }) }
) -Force

$settings.hooks | Add-Member -NotePropertyName "Stop" -NotePropertyValue @(
    @{ hooks = @(@{ type = "command"; command = $stopCmd; timeout = 10 }) }
) -Force

$settings.hooks | Add-Member -NotePropertyName "PreToolUse" -NotePropertyValue @(
    @{ matcher = "Bash|PowerShell"; hooks = @(@{ type = "command"; command = $blockCmd; timeout = 10 }) }
) -Force

$settings | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsPath -Encoding utf8
Write-Output "[3/4] hooks + env merged into $settingsPath"

# --- 4. GPTaku marketplace + plugins ---------------------------------------
Write-Output "[4/4] registering marketplace and installing plugins..."
claude plugin marketplace add https://github.com/fivetaku/gptaku_plugins.git

$plugins = @(
    "show-me-the-prd",
    "skillers-suda",
    "kkirikkiri",
    "insane-search",
    "insane-research",
    "insane-harness",
    "insane-design"
)
foreach ($p in $plugins) {
    claude plugin install "$p@gptaku-plugins"
}

Write-Output ""
Write-Output "Done. Open a NEW terminal (or run . `$PROFILE) and restart Claude Code (cc) to load everything."
