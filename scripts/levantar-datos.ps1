<#
    Levanta la capa de datos de DigitalFix y espera a que Oracle este listo.

    Oracle XE tarda entre 1 y 3 minutos en el primer arranque, porque crea la
    base desde cero. Los arranques siguientes son de unos 20 segundos.

    USO:
      .\scripts\levantar-datos.ps1
      .\scripts\levantar-datos.ps1 -Reiniciar    # borra los datos y empieza de cero
#>
param([switch]$Reiniciar)

$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot
$compose = Join-Path $raiz "compose\docker-compose.datos.yml"
$env_file = Join-Path $raiz ".env"

if (-not (Test-Path $env_file)) {
    Write-Host "No existe .env. Copialo desde .env.example y pon tus claves:" -ForegroundColor Yellow
    Write-Host "  Copy-Item .env.example .env" -ForegroundColor Yellow
    exit 1
}

if ($Reiniciar) {
    Write-Host "Borrando volumenes..." -ForegroundColor Yellow
    docker compose -f $compose --env-file $env_file down -v
}

Write-Host "Levantando Oracle XE..." -ForegroundColor Cyan
docker compose -f $compose --env-file $env_file up -d

Write-Host "Esperando a que reporte healthy (puede tardar 3 minutos la primera vez)..."
$limite = (Get-Date).AddMinutes(6)
while ((Get-Date) -lt $limite) {
    $estado = docker inspect --format '{{.State.Health.Status}}' digitalfix-oracle 2>$null
    if ($estado -eq "healthy") {
        Write-Host ""
        Write-Host "Oracle listo en localhost:1521/XEPDB1" -ForegroundColor Green
        Write-Host "Esquemas: DFX_USUARIOS, DFX_CATALOG, DFX_WORKORDERS, DFX_REPORT, DFX_AUDIT" -ForegroundColor Green
        exit 0
    }
    if ($estado -eq "unhealthy") {
        Write-Host ""
        Write-Host "El contenedor quedo unhealthy. Revisa los logs:" -ForegroundColor Red
        Write-Host "  docker logs digitalfix-oracle --tail 50" -ForegroundColor Red
        exit 1
    }
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 5
}
Write-Host ""
Write-Host "Se agoto la espera. Revisa: docker logs digitalfix-oracle --tail 50" -ForegroundColor Red
exit 1
