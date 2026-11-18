# SessionStart hook of the inventor plugin: warns when uv is missing.
# Prints Claude Code hook JSON. Called from hooks/hooks.json
# via $env:CLAUDE_PLUGIN_ROOT. Keep this file ASCII-only: Windows PowerShell 5.1
# reads BOM-less scripts as ANSI, so non-ASCII characters are built from char codes.
# -Lang overrides the system UI language (e.g. for testing); -Force skips the uv check.

param([string]$Lang = (Get-UICulture).TwoLetterISOLanguageName, [switch]$Force)

if (-not $Force -and (Get-Command uv -ErrorAction SilentlyContinue)) { exit 0 }

$texts = @{
    en = @{
        Title   = 'inventor plugin: uv is not installed'
        Reason  = 'The Inventor MCP server cannot start.'
        Install = 'Install: '
        Restart = 'Then restart Claude Code.'
    }
    de = @{
        Title   = 'inventor-Plugin: uv ist nicht installiert'
        Reason  = 'Der Inventor-MCP-Server kann nicht starten.'
        Install = 'Installation: '
        Restart = 'Danach Claude Code neu starten.'
    }
}

if (-not $texts.ContainsKey($Lang)) { $Lang = 'en' }
$t = $texts[$Lang]
$cmd = 'winget install --id astral-sh.uv'

$esc   = [string][char]27
$reset = "$esc[0m"
$frame = "$esc[33m"    # yellow
$title = "$esc[1;31m"  # bold red
$code  = "$esc[1;36m"  # bold cyan
$dim   = "$esc[2m"

# Each row: plain text (for width) and colored text (for output).
$rows = @(
    @{ Plain = $t.Title;               Color = $title + $t.Title + $reset }
    @{ Plain = $t.Reason;              Color = $t.Reason }
    @{ Plain = $t.Install + $cmd;      Color = $t.Install + $code + $cmd + $reset }
    @{ Plain = $t.Restart;             Color = $dim + $t.Restart + $reset }
)

$width = ($rows | ForEach-Object { $_.Plain.Length } | Measure-Object -Maximum).Maximum
$hLine = ([string][char]0x2500) * ($width + 2)
$vLine = $frame + [char]0x2502 + $reset

$lines = @($frame + [char]0x250C + $hLine + [char]0x2510 + $reset)
foreach ($r in $rows) {
    $lines += $vLine + ' ' + $r.Color + (' ' * ($width - $r.Plain.Length)) + ' ' + $vLine
}
$lines += $frame + [char]0x2514 + $hLine + [char]0x2518 + $reset

$json = @{
    systemMessage      = "`n" + ($lines -join "`n")
    hookSpecificOutput = @{
        hookEventName     = 'SessionStart'
        additionalContext = 'inventor plugin: uv is not installed, so the Inventor MCP server cannot start. Install it with: winget install --id astral-sh.uv, then restart Claude Code.'
    }
} | ConvertTo-Json -Compress

# Escape non-ASCII as \uXXXX so the output survives any console code page.
[regex]::Replace($json, '[^\x00-\x7F]', { param($m) '\u{0:x4}' -f [int][char]$m.Value })
