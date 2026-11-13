<#
.SYNOPSIS
    Gerenciador de Ativos Externos 3D (CC0) para Blackout Strike.
.DESCRIPTION
    Verifica atualizacoes remotas e sincroniza modelos 3D externos (Kenney e KayKit)
    com base no catalogo tools/assets_manifest.json.
.PARAMETER Action
    Acao a executar: 'Check' (apenas checar) ou 'Sync' (baixar e atualizar). Padrao: 'Check'.
.PARAMETER Format
    Formato desejado dos modelos: 'glb' ou 'gltf'. Padrao: 'glb'.
.PARAMETER Force
    Forca o re-download e reinstalacao mesmo se as versoes coincidirem.
.EXAMPLE
    pwsh tools/manage_assets.ps1 -Action Check
    pwsh tools/manage_assets.ps1 -Action Sync -Format glb
    pwsh tools/manage_assets.ps1 -Action Sync -Format gltf -Force
#>

[CmdletBinding()]
param(
    [ValidateSet("Check", "Sync", "Clean")]
    [string]$Action = "Check",

    [ValidateSet("glb", "gltf")]
    [string]$Format = "glb",

    [switch]$Force
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$ManifestPath = Join-Path $ScriptDir "assets_manifest.json"
$ScratchDir = Join-Path $ProjectRoot "scratch/asset_sync_tmp"

if (-not (Test-Path $ManifestPath)) {
    Write-Error "Arquivo de manifesto nao encontrado: $ManifestPath"
    exit 1
}

$Manifest = Get-Content -Raw $ManifestPath | ConvertFrom-Json
$HeadersKenney = @{
    "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
    "Referer"    = "https://kenney.nl/assets"
}
$HeadersGithub = @{
    "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
    "Accept"     = "application/vnd.github.v3+json"
}

function Get-RemoteVersion {
    param (
        [PSCustomObject]$Asset
    )

    if ($Asset.provider -eq "github") {
        try {
            $apiUrl = "https://api.github.com/repos/$($Asset.repo)/commits/$($Asset.branch)"
            $res = Invoke-RestMethod -Uri $apiUrl -Headers $HeadersGithub -Method Get -TimeoutSec 10
            return $res.sha.Substring(0, 10)
        }
        catch {
            Write-Warning "Falha ao consultar GitHub para $($Asset.id): $_"
            return "UNKNOWN"
        }
    }
    elseif ($Asset.provider -eq "kenney") {
        try {
            $pageUrl = "https://kenney.nl/$($Asset.slug)"
            $pageHtml = (Invoke-WebRequest -Uri $pageUrl -Headers $HeadersKenney -TimeoutSec 10).Content
            if ($pageHtml -match "preview\.png\?v=([a-zA-Z0-9_\-]+)|pages/assets/[^/]+/([a-zA-Z0-9_\-]+)/preview\.png") {
                $hash = if ($Matches[1]) { $Matches[1] } else { $Matches[2] }
                return $hash.Substring(0, [Math]::Min(10, $hash.Length))
            }
            # Fallback para token de download
            $dlApi = "https://kenney.nl/download-link/$($Asset.hex_id)"
            $dlRes = Invoke-RestMethod -Uri $dlApi -Headers $HeadersKenney -Method Get -TimeoutSec 10
            if ($dlRes.url -match "/([a-f0-9]{32,})") {
                return $Matches[1].Substring(0, 10)
            }
            return "v1.0"
        }
        catch {
            Write-Warning "Falha ao consultar Kenney para $($Asset.id): $_"
            return "UNKNOWN"
        }
    }
    elseif ($Asset.provider -eq "polyhaven") {
        return "1k-cc0"
    }
    return "UNKNOWN"
}

function Sync-PolyHavenAsset {
    param (
        [PSCustomObject]$Asset,
        [string]$TargetDir
    )

    $phId = $Asset.polyhaven_id
    $res = if ($Asset.resolution) { $Asset.resolution } else { "1k" }
    $apiUrl = "https://api.polyhaven.com/files/$phId"
    Write-Host "  -> Consultando Poly Haven API: $apiUrl" -ForegroundColor Cyan
    $files = Invoke-RestMethod -Uri $apiUrl -Headers @{"User-Agent"="BlackoutStrike"} -Method Get -TimeoutSec 20

    if (-not (Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
    }

    $downloaded = 0
    if ($Asset.asset_type -eq "texture") {
        foreach ($channel in @("Diffuse", "nor_gl", "arm")) {
            $chObj = $files.$channel
            if ($chObj -and $chObj.$res -and $chObj.$res.jpg) {
                $url = $chObj.$res.jpg.url
                $fileName = [System.IO.Path]::GetFileName($url)
                $dest = Join-Path $TargetDir $fileName
                Write-Host "     Baixando $fileName..." -ForegroundColor DarkCyan
                Invoke-WebRequest -Uri $url -OutFile $dest -UserAgent "BlackoutStrike" -TimeoutSec 60
                $downloaded++
            }
        }
    }
    elseif ($Asset.asset_type -eq "hdri") {
        if ($files.hdri -and $files.hdri.$res -and $files.hdri.$res.hdr) {
            $url = $files.hdri.$res.hdr.url
            $fileName = [System.IO.Path]::GetFileName($url)
            $dest = Join-Path $TargetDir $fileName
            Write-Host "     Baixando $fileName..." -ForegroundColor DarkCyan
            Invoke-WebRequest -Uri $url -OutFile $dest -UserAgent "BlackoutStrike" -TimeoutSec 60
            $downloaded++
        }
    }
    elseif ($Asset.asset_type -eq "model") {
        $gltfInfo = $files.gltf.$res.gltf
        if ($gltfInfo) {
            $mainUrl = $gltfInfo.url
            $mainName = [System.IO.Path]::GetFileName($mainUrl)
            $mainDest = Join-Path $TargetDir $mainName
            Write-Host "     Baixando $mainName..." -ForegroundColor DarkCyan
            Invoke-WebRequest -Uri $mainUrl -OutFile $mainDest -UserAgent "BlackoutStrike" -TimeoutSec 60
            $downloaded++

            if ($gltfInfo.include) {
                foreach ($prop in $gltfInfo.include.PSObject.Properties) {
                    $relPath = $prop.Name
                    $incUrl = $prop.Value.url
                    $incDest = Join-Path $TargetDir $relPath
                    $incParent = Split-Path -Parent $incDest
                    if (-not (Test-Path $incParent)) {
                        New-Item -ItemType Directory -Force -Path $incParent | Out-Null
                    }
                    Write-Host "     Baixando $relPath..." -ForegroundColor DarkCyan
                    Invoke-WebRequest -Uri $incUrl -OutFile $incDest -UserAgent "BlackoutStrike" -TimeoutSec 60
                    $downloaded++
                }
            }
        }
    }

    Write-Host "  -> Importados $downloaded arquivos Poly Haven para $TargetDir" -ForegroundColor Green
    return $downloaded
}

function Download-AssetArchive {
    param (
        [PSCustomObject]$Asset,
        [string]$DestinationZip
    )

    if ($Asset.provider -eq "github") {
        $zipUrl = "https://github.com/$($Asset.repo)/archive/refs/heads/$($Asset.branch).zip"
        Write-Host "  -> Baixando arquivo do GitHub: $zipUrl" -ForegroundColor Cyan
        Invoke-WebRequest -Uri $zipUrl -OutFile $DestinationZip -Headers $HeadersGithub -TimeoutSec 60
    }
    elseif ($Asset.provider -eq "kenney") {
        $dlApi = "https://kenney.nl/download-link/$($Asset.hex_id)"
        Write-Host "  -> Solicitando link assinado do Kenney: $dlApi" -ForegroundColor Cyan
        $dlRes = Invoke-RestMethod -Uri $dlApi -Headers $HeadersKenney -Method Get -TimeoutSec 15
        if (-not $dlRes.url) {
            throw "Link de download invalido retornado pela API do Kenney: $($dlRes | Out-String)"
        }
        Write-Host "  -> Baixando pacote do Kenney..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $dlRes.url -OutFile $DestinationZip -Headers $HeadersKenney -TimeoutSec 90
    }
}

function Extract-AssetModels {
    param (
        [PSCustomObject]$Asset,
        [string]$ZipPath,
        [string]$ExtractDir,
        [string]$TargetDir,
        [string]$DesiredFormat
    )

    Expand-Archive -Path $ZipPath -DestinationPath $ExtractDir -Force

    if (-not (Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null
    }

    $allFiles = Get-ChildItem -Path $ExtractDir -Recurse -File
    $matchedCount = 0

    if ($DesiredFormat -eq "gltf") {
        $targetModels = $allFiles | Where-Object { $_.Extension -eq ".gltf" }
        if ($targetModels.Count -eq 0) {
            Write-Warning "Formato gltf nao encontrado para $($Asset.id). Utilizando glb como fallback."
            $targetModels = $allFiles | Where-Object { $_.Extension -eq ".glb" }
        }
    }
    else {
        $targetModels = $allFiles | Where-Object { $_.Extension -eq ".glb" }
        if ($targetModels.Count -eq 0) {
            Write-Warning "Formato glb nao encontrado para $($Asset.id). Utilizando gltf como fallback."
            $targetModels = $allFiles | Where-Object { $_.Extension -eq ".gltf" }
        }
    }

    # Copiar modelos encontrados
    foreach ($m in $targetModels) {
        Copy-Item -Path $m.FullName -Destination (Join-Path $TargetDir $m.Name) -Force
        $matchedCount++

        # Se for .gltf, copiar arquivo .bin correspondente se existir
        if ($m.Extension -eq ".gltf") {
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($m.Name)
            $binFile = $allFiles | Where-Object { $_.Name -eq "$baseName.bin" -and $_.DirectoryName -eq $m.DirectoryName }
            if ($binFile) {
                Copy-Item -Path $binFile.FullName -Destination (Join-Path $TargetDir $binFile.Name) -Force
            }
        }
    }

    # Copiar texturas PNG associadas
    $textures = $allFiles | Where-Object { $_.Extension -eq ".png" -and $_.FullName -match "texture|Textures|Textures/" }
    if ($textures) {
        $texTarget = Join-Path $TargetDir "textures"
        if (-not (Test-Path $texTarget)) {
            New-Item -ItemType Directory -Force -Path $texTarget | Out-Null
        }
        foreach ($t in $textures) {
            Copy-Item -Path $t.FullName -Destination (Join-Path $texTarget $t.Name) -Force
        }
    }

    Write-Host "  -> Importados $matchedCount modelos para $TargetDir" -ForegroundColor Green
    return $matchedCount
}

# ----------------- EXECUCAO PRINCIPAL -----------------

Write-Host "==========================================================" -ForegroundColor Yellow
Write-Host " Blackout Strike - Gerenciador de Ativos 3D ($Action)" -ForegroundColor Yellow
Write-Host " Formato Solicitado: $Format | Forcar Download: $Force" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Yellow

$StatusReport = @()
$ManifestModified = $false

foreach ($asset in $Manifest.assets) {
    Write-Host "`nProcessando: $($asset.name)..." -ForegroundColor White

    $targetFullPath = Join-Path $ProjectRoot $asset.target_dir
    if ($asset.provider -eq "polyhaven") {
        $hasLocalFiles = (Test-Path $targetFullPath) -and ((Get-ChildItem -Path $targetFullPath -File).Count -gt 0)
    }
    else {
        $hasLocalFiles = (Test-Path $targetFullPath) -and ((Get-ChildItem -Path $targetFullPath -File -Filter "*.$Format").Count -gt 0)
    }

    $remoteVer = Get-RemoteVersion -Asset $asset
    $installedVer = $asset.installed_version

    $status = "UP_TO_DATE"
    if (-not $installedVer -or -not $hasLocalFiles) {
        $status = "NOT_INSTALLED"
    }
    elseif ($remoteVer -ne "UNKNOWN" -and $remoteVer -ne $installedVer) {
        $status = "OUTDATED"
    }

    $StatusReport += [PSCustomObject]@{
        Id            = $asset.id
        Destino       = $asset.target_dir
        Instalado     = if ($installedVer) { $installedVer } else { "Nenhum" }
        Remoto        = $remoteVer
        Status        = $status
    }

    if ($Action -eq "Sync") {
        $shouldDownload = ($status -ne "UP_TO_DATE") -or $Force

        if ($shouldDownload) {
            Write-Host "  Iniciando sincronizacao para $($asset.id) ($status)..." -ForegroundColor Cyan

            if (Test-Path $ScratchDir) {
                Remove-Item -Recurse -Force $ScratchDir
            }
            New-Item -ItemType Directory -Force -Path $ScratchDir | Out-Null

            $zipFile = Join-Path $ScratchDir "$($asset.id).zip"
            $extractFolder = Join-Path $ScratchDir "extracted"

            try {
                if ($asset.provider -eq "polyhaven") {
                    $count = Sync-PolyHavenAsset -Asset $asset -TargetDir $targetFullPath
                    if ($count -gt 0) {
                        $asset.installed_version = $remoteVer
                        $asset.installed_format = $asset.asset_type
                        $asset.last_checked = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
                        $ManifestModified = $true
                    }
                }
                else {
                    Download-AssetArchive -Asset $asset -DestinationZip $zipFile
                    $count = Extract-AssetModels -Asset $asset -ZipPath $zipFile -ExtractDir $extractFolder -TargetDir $targetFullPath -DesiredFormat $Format

                    if ($count -gt 0) {
                        $asset.installed_version = $remoteVer
                        $asset.installed_format = $Format
                        $asset.last_checked = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
                        $ManifestModified = $true
                    }
                }
            }
            catch {
                Write-Error "Falha na sincronizacao de $($asset.id): $_"
            }
            finally {
                if (Test-Path $ScratchDir) {
                    Remove-Item -Recurse -Force $ScratchDir
                }
            }
        }
        else {
            Write-Host "  -> Ja atualizado na versao $installedVer. Pulando download." -ForegroundColor Green
            $asset.last_checked = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
            $ManifestModified = $true
        }
    }
}

# Salvar manifesto atualizado se houve modificacoes
if ($ManifestModified) {
    $Manifest | ConvertTo-Json -Depth 5 | Set-Content -Path $ManifestPath -Encoding UTF8
    Write-Host "`n[OK] Manifesto $ManifestPath atualizado com sucesso." -ForegroundColor Green
}

# Exibir tabela de diagnostico
Write-Host "`nRelatorio de Estado dos Ativos:" -ForegroundColor Yellow
$StatusReport | Format-Table -AutoSize

# Se foi Sync e temos o Godot instalado, disparar compilacao de metadados .import
if ($Action -eq "Sync") {
    $godotCmd = Get-Command godot -ErrorAction SilentlyContinue
    if ($godotCmd) {
        Write-Host "`nDisparando Godot Headless para compilar metadados .import..." -ForegroundColor Cyan
        Push-Location $ProjectRoot
        try {
            & godot --headless --editor --quit 2>&1 | Out-Null
            Write-Host "[OK] Metadados .import compilados pelo Godot." -ForegroundColor Green
        }
        catch {
            Write-Warning "Aviso: Nao foi possivel rodar godot --headless: $_"
        }
        finally {
            Pop-Location
        }
    }
}

Write-Host "`nConcluido com sucesso." -ForegroundColor Green
