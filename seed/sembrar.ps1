<#
    DigitalFix - carga los datos semilla en la base local.

    Corre los scripts de esta carpeta dentro del contenedor de Oracle, cada uno
    con el usuario del esquema que le corresponde.

    ANTES de ejecutarlo, cada microservicio tiene que haber aplicado sus
    migraciones al menos una vez: la semilla llena tablas, no las crea.

        01-empresas-y-usuarios.sql   ->  DFX_USUARIOS   (ms-digitalfix-usuarios)
        02-catalogo-de-ejemplo.sql   ->  DFX_CATALOG    (ms-digitalfix-catalog)

    USO:
      .\seed\sembrar.ps1
      .\seed\sembrar.ps1 -Clave otra_clave        # si cambiaste la de los esquemas
      .\seed\sembrar.ps1 -Solo usuarios           # solo uno de los dos
#>
param(
    [string]$Contenedor = "digitalfix-oracle",
    [string]$Servicio = "XEPDB1",
    [string]$Clave = "digitalfix",
    [ValidateSet("todo", "usuarios", "catalogo")][string]$Solo = "todo"
)

$ErrorActionPreference = "Stop"
$carpeta = $PSScriptRoot

function Ejecutar {
    param([string]$Esquema, [string]$Archivo, [string]$Que)

    $ruta = Join-Path $carpeta $Archivo
    if (-not (Test-Path $ruta)) {
        Write-Host "  ! no encuentro $Archivo" -ForegroundColor Yellow
        return
    }

    Write-Host ""
    Write-Host "=== $Que  ($Esquema)" -ForegroundColor Cyan

    # El SQL se manda por la entrada estandar de sqlplus dentro del contenedor:
    # asi no hay que copiar archivos ni montar volumenes nuevos.
    $sql = Get-Content -Raw -Path $ruta
    $sql = $sql + "`nEXIT;`n"

    $sql | docker exec -i $Contenedor sqlplus -S "$Esquema/$Clave@//localhost:1521/$Servicio"

    if ($LASTEXITCODE -ne 0) {
        throw "sqlplus devolvio $LASTEXITCODE al correr $Archivo"
    }
}

# --- comprobaciones previas --------------------------------------------------

$estado = docker inspect --format '{{.State.Health.Status}}' $Contenedor 2>$null
if (-not $estado) {
    Write-Host "El contenedor $Contenedor no existe. Levanta la base primero:" -ForegroundColor Red
    Write-Host "  .\scripts\levantar-datos.ps1" -ForegroundColor Red
    exit 1
}
if ($estado -ne "healthy") {
    Write-Host "El contenedor esta en estado '$estado'. Espera a que quede healthy." -ForegroundColor Red
    exit 1
}

Write-Host "Sembrando datos en $Contenedor ($Servicio)" -ForegroundColor Cyan

if ($Solo -eq "todo" -or $Solo -eq "usuarios") {
    Ejecutar -Esquema "DFX_USUARIOS" -Archivo "01-empresas-y-usuarios.sql" `
             -Que "20 empresas y un usuario por rol"
}

if ($Solo -eq "todo" -or $Solo -eq "catalogo") {
    Ejecutar -Esquema "DFX_CATALOG" -Archivo "02-catalogo-de-ejemplo.sql" `
             -Que "catalogo de ejemplo de las tres primeras empresas"
}

Write-Host ""
Write-Host "Listo." -ForegroundColor Green
Write-Host "Si alguno fallo con ORA-00942 (tabla no existe), ese microservicio" -ForegroundColor DarkGray
Write-Host "todavia no ha aplicado sus migraciones: levantalo una vez y repite." -ForegroundColor DarkGray
