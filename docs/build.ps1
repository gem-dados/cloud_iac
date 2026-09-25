param(
    [Parameter(Mandatory = $false)]
    [string]$TectonicPath = "tectonic",

    [Parameter(Mandatory = $false)]
    [ValidateSet("auto", "tectonic", "xelatex")]
    [string]$Engine = "auto"
)

$ErrorActionPreference = "Stop"
$SourceDir = Join-Path $PSScriptRoot "latex"
$OutputDir = $PSScriptRoot

# Determinar qual compilador utilizar
$UseTectonic = $false
if ($Engine -eq "tectonic") {
    $UseTectonic = $true
} elseif ($Engine -eq "xelatex") {
    $UseTectonic = $false
} else {
    # auto: prefere tectonic se estiver disponível, caso contrário xelatex
    if (Get-Command $TectonicPath -ErrorAction SilentlyContinue) {
        $UseTectonic = $true
    } elseif (Get-Command "xelatex" -ErrorAction SilentlyContinue) {
        $UseTectonic = $false
    } else {
        throw "Nenhum compilador TeX encontrado (nem Tectonic nem XeLaTeX). Instale um deles para continuar."
    }
}

$Documents = @(
    @{ Source = "documentacao_tecnica.tex"; Output = "GEMDados_Documentacao_Tecnica.pdf" },
    @{ Source = "documentacao_negocio.tex"; Output = "GEMDados_Documentacao_Negocio.pdf" }
)

if ($UseTectonic) {
    Write-Host "Compilando com Tectonic..."
    foreach ($Document in $Documents) {
        & $TectonicPath --keep-logs --synctex --outdir $OutputDir (Join-Path $SourceDir $Document.Source)
        if ($LASTEXITCODE -ne 0) {
            throw "Falha ao compilar $($Document.Source)."
        }

        $Generated = Join-Path $OutputDir ([System.IO.Path]::GetFileNameWithoutExtension($Document.Source) + ".pdf")
        $Final = Join-Path $OutputDir $Document.Output
        Move-Item -Force -LiteralPath $Generated -Destination $Final
    }
} else {
    Write-Host "Compilando com XeLaTeX (MiKTeX)..."
    Push-Location $SourceDir
    try {
        foreach ($Document in $Documents) {
            $base = [System.IO.Path]::GetFileNameWithoutExtension($Document.Source)
            Write-Host "Compilando $($Document.Source) (passadas 1 e 2)..."
            & xelatex -interaction=nonstopmode $Document.Source | Out-Null
            & xelatex -interaction=nonstopmode $Document.Source | Out-Null

            $localPdf = "$base.pdf"
            $destPdf = Join-Path $OutputDir $Document.Output

            if (-not (Test-Path $localPdf)) {
                throw "Falha ao gerar o PDF para $($Document.Source)."
            }

            Move-Item -Force -LiteralPath $localPdf -Destination $destPdf

            # Remove arquivos intermediários do LaTeX
            Get-ChildItem -Path $SourceDir -Filter "$base.*" | Where-Object { $_.Extension -ne ".tex" } | Remove-Item -Force
        }
    } finally {
        Pop-Location
    }
}

Write-Host "PDFs gerados com sucesso em $OutputDir"
