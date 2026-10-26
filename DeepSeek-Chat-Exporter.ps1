# DeepSeek-Chat-Exporter.ps1 - v1.0
# Esporta conversazioni DeepSeek (JSON) in storie HTML/TXT
# Con validazione JSON, log su file, gestione errori

#Requires -Version 7.0

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ============================================================
# CONTROLLO VERSIONE POWERSHELL
# ============================================================
if ($PSVersionTable.PSVersion.Major -lt 7) {
    [System.Windows.Forms.MessageBox]::Show(
        "Questo tool richiede PowerShell 7 o superiore.`n`n" +
        "Versione attuale: $($PSVersionTable.PSVersion)`n`n" +
        "Scarica PowerShell 7 da: https://aka.ms/powershell",
        "PowerShell 7 richiesto",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    exit
}

# ============================================================
# LOGGING
# ============================================================
$script:logFile = $null

function Start-Log {
    param([string]$Folder)
    if (-not (Test-Path $Folder)) { New-Item -ItemType Directory -Path $Folder -Force | Out-Null }
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $script:logFile = Join-Path $Folder "deepseek_exporter_$timestamp.log"
    @(
        "============================================================",
        " DEEPSEEK CHAT EXPORTER - LOG",
        "============================================================",
        "Data inizio: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
        "============================================================",
        ""
    ) | Set-Content -Path $script:logFile -Encoding UTF8
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    if (-not $script:logFile) { return }
    $line = "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Message"
    Add-Content -Path $script:logFile -Value $line -Encoding UTF8
}

# ============================================================
# FUNZIONI DI UTILITA
# ============================================================
function Write-Step {
    param([string]$Message, [string]$Color = "Cyan")
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor $Color
    Write-Host "  $Message" -ForegroundColor $Color
    Write-Host ("=" * 60) -ForegroundColor $Color
}

function Write-Success { param([string]$Message) Write-Host "  [OK] $Message" -ForegroundColor Green }
function Write-ErrorMsg { param([string]$Message) Write-Host "  [X] $Message" -ForegroundColor Red }
function Write-Warning { param([string]$Message) Write-Host "  [!] $Message" -ForegroundColor Yellow }
function Write-Info { param([string]$Message) Write-Host "  [i] $Message" -ForegroundColor Gray }

function Test-MessaggioVuoto {
    param([string]$testo)
    if ([string]::IsNullOrWhiteSpace($testo)) { return $true }
    if ($testo -match '^[\s]*$') { return $true }
    if ($testo -match '^[\*\-_\.\/\\\s]+$') { return $true }
    if ($testo.Length -le 2 -and $testo -match '^[\*\-_\.\/\\]+$') { return $true }
    $pulito = $testo -replace '[\*\-_\.\/\\\s]', ''
    if ([string]::IsNullOrWhiteSpace($pulito)) { return $true }
    return $false
}

function Converti-TestoInHTML {
    param([string]$testo)
    $testo = $testo -replace '&', '&amp;'
    $testo = $testo -replace '<', '&lt;'
    $testo = $testo -replace '>', '&gt;'
    $testo = $testo -replace '"', '&quot;'
    $testo = $testo -replace "`n", '<br>'
    return $testo
}

# ============================================================
# STEP 1: SELEZIONE FILE JSON
# ============================================================
Clear-Host
Write-Host "+==========================================================+" -ForegroundColor Magenta
Write-Host "|      DEEPSEEK CHAT EXPORTER v1.0                         |" -ForegroundColor Magenta
Write-Host "|      Esporta conversazioni DeepSeek in HTML/TXT          |" -ForegroundColor Magenta
Write-Host "+==========================================================+" -ForegroundColor Magenta

Write-Step "STEP 1: Selezione file JSON" "Cyan"

$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog.Title = "Seleziona il file JSON esportato da DeepSeek"
$OpenFileDialog.Filter = "File JSON (*.json)|*.json|Tutti i file (*.*)|*.*"
$OpenFileDialog.InitialDirectory = [Environment]::GetFolderPath('Desktop')

if ($OpenFileDialog.ShowDialog() -eq 'OK') {
    $filePath = $OpenFileDialog.FileName
    Write-Success "File: $filePath"
} else {
    Write-ErrorMsg "Nessun file selezionato. Operazione annullata."
    exit
}

# ============================================================
# STEP 2: LEGGI E VALIDA JSON
# ============================================================
Write-Step "STEP 2: Lettura e validazione JSON" "Cyan"

try {
    $jsonRaw = Get-Content -Path $filePath -Encoding UTF8 -Raw
    Write-Success "File caricato ($($jsonRaw.Length) caratteri)"
} catch {
    Write-ErrorMsg "Errore lettura: $($_.Exception.Message)"
    [System.Windows.Forms.MessageBox]::Show("Errore lettura file: $($_.Exception.Message)", "Errore", "OK", "Error")
    exit
}

# Validazione JSON (controllo base)
try {
    $null = $jsonRaw | ConvertFrom-Json
    Write-Success "JSON valido"
} catch {
    Write-ErrorMsg "JSON non valido: $($_.Exception.Message)"
    $resp = [System.Windows.Forms.MessageBox]::Show(
        "Il file JSON sembra non valido o corrotto.`n`n" +
        "Errore: $($_.Exception.Message)`n`n" +
        "Vuoi provare comunque?",
        "JSON non valido",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    if ($resp -ne "Yes") { exit }
}

# ============================================================
# STEP 3: PERSONALIZZA NOMI
# ============================================================
Write-Step "STEP 3: Personalizza nomi" "Cyan"
Write-Info "Lascia vuoto per NON estrarre quel ruolo"

$nomeUser = Read-Host "`nNome per USER (es. Fabry) [vuoto = salta]"
$nomeAssistant = Read-Host "Nome per ASSISTANT (es. DeepSeek) [vuoto = salta]"

Write-Host ""
Write-Host "Configurazione:" -ForegroundColor Cyan
if ([string]::IsNullOrWhiteSpace($nomeUser)) {
    Write-Warning "USER: NON estratto"
} else {
    Write-Success "USER: $nomeUser"
}
if ([string]::IsNullOrWhiteSpace($nomeAssistant)) {
    Write-Warning "ASSISTANT: NON estratto"
} else {
    Write-Success "ASSISTANT: $nomeAssistant"
}

if ([string]::IsNullOrWhiteSpace($nomeUser) -and [string]::IsNullOrWhiteSpace($nomeAssistant)) {
    Write-ErrorMsg "Devi specificare almeno un nome!"
    [System.Windows.Forms.MessageBox]::Show("Specifica almeno un nome (USER o ASSISTANT).", "Errore", "OK", "Error")
    exit
}

# ============================================================
# STEP 4: ESTRAZIONE
# ============================================================
Write-Step "STEP 4: Estrazione messaggi" "Cyan"

$patternFragments = '"fragments"\s*:\s*\[([^\]]*)\]'
$matchesFragments = [regex]::Matches($jsonRaw, $patternFragments)

$messaggiOrdinati = @()

foreach ($match in $matchesFragments) {
    $fragmentBlock = $match.Groups[1].Value
    $patternTypeContent = '"type"\s*:\s*"([^"]+)"\s*,\s*"content"\s*:\s*"((?:[^"\\]|\\.)*)"'
    $matchesTypeContent = [regex]::Matches($fragmentBlock, $patternTypeContent)

    foreach ($tc in $matchesTypeContent) {
        if ($tc.Groups.Count -gt 2) {
            $tipo = $tc.Groups[1].Value
            $contenuto = $tc.Groups[2].Value
            $contenuto = $contenuto -replace '\\"', '"'
            $contenuto = $contenuto -replace '\\n', "`n"
            $contenuto = $contenuto -replace '\\t', "`t"
            $contenuto = $contenuto -replace '\\\\', '\'
            $contenuto = $contenuto.Trim()

            if (-not (Test-MessaggioVuoto -testo $contenuto)) {
                $messaggiOrdinati += [PSCustomObject]@{
                    Tipo = $tipo
                    Contenuto = $contenuto
                }
            }
        }
    }
}

Write-Success "Trovati $($messaggiOrdinati.Count) messaggi"

if ($messaggiOrdinati.Count -eq 0) {
    Write-ErrorMsg "Nessun messaggio trovato."
    [System.Windows.Forms.MessageBox]::Show("Nessun messaggio trovato nel JSON.", "Errore", "OK", "Warning")
    exit
}

# ============================================================
# STEP 5: RICOSTRUISCI CONVERSAZIONE
# ============================================================
Write-Step "STEP 5: Ricostruzione conversazione" "Cyan"

$users = @()
$assistants = @()
$conversazione = @()

foreach ($msg in $messaggiOrdinati) {
    if ($msg.Tipo -eq "REQUEST" -and -not [string]::IsNullOrWhiteSpace($nomeUser)) {
        $users += $msg.Contenuto
        $conversazione += [PSCustomObject]@{ Ruolo = $nomeUser; Contenuto = $msg.Contenuto }
    } elseif ($msg.Tipo -eq "RESPONSE" -and -not [string]::IsNullOrWhiteSpace($nomeAssistant)) {
        $assistants += $msg.Contenuto
        $conversazione += [PSCustomObject]@{ Ruolo = $nomeAssistant; Contenuto = $msg.Contenuto }
    }
}

if (-not [string]::IsNullOrWhiteSpace($nomeUser)) {
    Write-Info "USER ($nomeUser): $($users.Count) messaggi"
}
if (-not [string]::IsNullOrWhiteSpace($nomeAssistant)) {
    Write-Info "ASSISTANT ($nomeAssistant): $($assistants.Count) messaggi"
}

if ($conversazione.Count -eq 0) {
    Write-ErrorMsg "Nessun messaggio da estrarre con la configurazione attuale."
    [System.Windows.Forms.MessageBox]::Show("Nessun messaggio da estrarre.", "Errore", "OK", "Warning")
    exit
}

# ============================================================
# STEP 6: INFORMAZIONI STORIA
# ============================================================
Write-Step "STEP 6: Informazioni storia" "Cyan"

$titolo = Read-Host "`nTitolo della storia"
if ([string]::IsNullOrWhiteSpace($titolo)) { $titolo = "Conversazione estratta" }

$data = Read-Host "Data (es. 15 Agosto 2026) [vuoto = 'Data sconosciuta']"
if ([string]::IsNullOrWhiteSpace($data)) { $data = "Data sconosciuta" }

$nomeFile = Read-Host "Nome file (senza estensione) [vuoto = generato da titolo]"
if ([string]::IsNullOrWhiteSpace($nomeFile)) {
    $nomeFile = $titolo -replace '[^a-zA-Z0-9]', '-'
    $nomeFile = $nomeFile -replace '-+', '-'
    $nomeFile = $nomeFile.Trim('-')
    Write-Warning "Nome generato: $nomeFile"
}

# ============================================================
# STEP 7: GENERAZIONE OUTPUT
# ============================================================
Write-Step "STEP 7: Generazione output" "Cyan"

$cartellaStorie = Join-Path -Path (Split-Path $filePath -Parent) -ChildPath "storie"
if (-not (Test-Path $cartellaStorie)) { New-Item -ItemType Directory -Path $cartellaStorie -Force | Out-Null }

# Avvia log nella cartella storie
Start-Log -Folder $cartellaStorie
Write-Log "File JSON: $filePath" "INFO"
Write-Log "Titolo: $titolo" "INFO"
Write-Log "Messaggi totali: $($conversazione.Count)" "INFO"

$outputFileHTML = Join-Path -Path $cartellaStorie -ChildPath "$nomeFile.html"
$outputFileTXT = Join-Path -Path $cartellaStorie -ChildPath "$nomeFile.txt"

# Costruisci corpo
$corpoHTML = ""
$corpoTXT = ""

foreach ($msg in $conversazione) {
    $testoHTML = Converti-TestoInHTML -testo $msg.Contenuto
    $corpoHTML += @"
        <div class="dialogue">
            <strong>$($msg.Ruolo):</strong> $testoHTML
        </div>
"@
    $corpoTXT += "[$($msg.Ruolo)] $($msg.Contenuto)`n`n"
}

# Genera HTML
try {
    $htmlFinale = @"
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$titolo</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, sans-serif; background: #000; color: #c0c0c0; padding: 20px; max-width: 1200px; margin: 0 auto; }
        .story-card { background: #0a0505; border-radius: 12px; padding: 25px; border: 1px solid #1a0a0a; }
        .story-card h3 { color: #e6e6e6; font-size: 1.4rem; margin-bottom: 10px; }
        .story-card h3 .date { font-size: 0.7rem; color: #555; font-weight: 300; }
        .story-card .dialogue { color: #e0c0c0; background: #0f0505; padding: 12px 18px; border-radius: 8px; border-left: 3px solid #cc3333; margin: 10px 0; }
    </style>
</head>
<body>
<div class="story-card">
    <h3>$titolo <span class="date">— $data</span></h3>
    $corpoHTML
</div>
</body>
</html>
"@
    $htmlFinale | Out-File -FilePath $outputFileHTML -Encoding UTF8
    Write-Success "HTML: $outputFileHTML"
    Write-Log "HTML generato: $outputFileHTML" "OK"
} catch {
    Write-ErrorMsg "Errore HTML: $($_.Exception.Message)"
    Write-Log "Errore HTML: $($_.Exception.Message)" "ERROR"
}

# Genera TXT
try {
    $headerTXT = "=" * 60 + "`n$titolo`nData: $data`n" + "=" * 60 + "`n`n"
    $footerTXT = "`n" + "=" * 60 + "`nFine della conversazione`n" + "=" * 60
    $corpoTXTCompleto = $headerTXT + $corpoTXT + $footerTXT
    $corpoTXTCompleto | Out-File -FilePath $outputFileTXT -Encoding UTF8
    Write-Success "TXT: $outputFileTXT"
    Write-Log "TXT generato: $outputFileTXT" "OK"
} catch {
    Write-ErrorMsg "Errore TXT: $($_.Exception.Message)"
    Write-Log "Errore TXT: $($_.Exception.Message)" "ERROR"
}

# ============================================================
# RIEPILOGO FINALE
# ============================================================
Write-Host ""
Write-Host "+==========================================+" -ForegroundColor Green
Write-Host "|      ESPORTAZIONE COMPLETATA!            |" -ForegroundColor Green
Write-Host "+==========================================+" -ForegroundColor Green
if (-not [string]::IsNullOrWhiteSpace($nomeUser)) {
    Write-Host "| USER:      $nomeUser ($($users.Count) msg)" -ForegroundColor White
}
if (-not [string]::IsNullOrWhiteSpace($nomeAssistant)) {
    Write-Host "| ASSISTANT: $nomeAssistant ($($assistants.Count) msg)" -ForegroundColor White
}
Write-Host "| HTML:      $outputFileHTML" -ForegroundColor White
Write-Host "| TXT:       $outputFileTXT" -ForegroundColor White
Write-Host "| Log:       $script:logFile" -ForegroundColor White
Write-Host "+==========================================+" -ForegroundColor Green
Write-Host ""

# Apri cartella output
$openFolder = Read-Host "Aprire la cartella storie? (S/N)"
if ($openFolder -eq 'S' -or $openFolder -eq 's') {
    Start-Process explorer.exe -ArgumentList $cartellaStorie
}

Write-Host ""
Write-Host "Premi un tasto per uscire..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
