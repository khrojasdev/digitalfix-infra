<#
    Levanta la capa de aplicaciones de DigitalFix.

    Da por hecho que la capa de datos ya esta arriba y healthy:
      .\scripts\levantar-datos.ps1

    Y que los repositorios estan clonados uno al lado del otro:
      DigitalFix\digitalfix-infra, ms-digitalfix-bff, ms-digitalfix-catalog, ...

    USO:
      .\scripts\levantar-apps.ps1
      .\scripts\levantar-apps.ps1 -Reconstruir    # fuerza el build de las imagenes
      .\scripts\levantar-apps.ps1 -Apagar
#>
param([switch]$Reconstruir, [switch]$Apagar)

$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot
$compose = Join-Path $raiz "compose\docker-compose.apps.yml"
$envFile = Join-Path $raiz ".env"

if (-not (Test-Path $envFile)) {
    Write-Host "No existe .env. Copialo desde .env.example y pon tus claves:" -ForegroundColor Yellow
    Write-Host "  Copy-Item .env.example .env" -ForegroundColor Yellow
    exit 1
}

if ($Apagar) {
    docker compose -f $compose --env-file $envFile down
    exit $LASTEXITCODE
}

# La red la crea el compose de datos: si no existe, es que la base no esta arriba.
$red = docker network ls --filter "name=digitalfix-datos_default" --format "{{.Name}}"
if (-not $red) {
    Write-Host "No encuentro la red de la capa de datos." -ForegroundColor Red
    Write-Host "Levanta primero la base:  .\scripts\levantar-datos.ps1" -ForegroundColor Red
    exit 1
}

$argumentos = @("compose", "-f", $compose, "--env-file", $envFile, "up", "-d")
if ($Reconstruir) { $argumentos += "--build" }

Write-Host "Levantando las aplicaciones..." -ForegroundColor Cyan
docker @argumentos
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "Esperando a que el BFF quede healthy..."
$limite = (Get-Date).AddMinutes(4)
while ((Get-Date) -lt $limite) {
    $estado = docker inspect --format '{{.State.Health.Status}}' digitalfix-bff 2>$null
    if ($estado -eq "healthy") {
        Write-Host ""
        Write-Host "Listo." -ForegroundColor Green
        Write-Host "  BFF       http://localhost:8080/api/catalog/services" -ForegroundColor Green
        Write-Host "  Catalogo  http://localhost:8082/actuator/health" -ForegroundColor Green
        exit 0
    }
    if ($estado -eq "unhealthy") {
        Write-Host ""
        Write-Host "El BFF quedo unhealthy. Revisa:" -ForegroundColor Red
        Write-Host "  docker logs digitalfix-bff --tail 60" -ForegroundColor Red
        exit 1
    }
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 5
}
Write-Host ""
Write-Host "Se agoto la espera. Revisa: docker logs digitalfix-bff --tail 60" -ForegroundColor Red
exit 1
