# Datos semilla

Datos de prueba para levantar el sistema y poder demostrarlo: **20 empresas, un
usuario por cada uno de los cuatro roles en cada una**, y un catálogo de ejemplo
en las tres primeras.

## Antes de sembrar

La semilla **llena tablas, no las crea**. Cada microservicio tiene que haber
aplicado sus migraciones al menos una vez:

| Script | Esquema | Lo crea |
|---|---|---|
| `01-empresas-y-usuarios.sql` | `DFX_USUARIOS` | `ms-digitalfix-usuarios` |
| `02-catalogo-de-ejemplo.sql` | `DFX_CATALOG` | `ms-digitalfix-catalog` |

Si un script falla con `ORA-00942: table or view does not exist`, es eso: ese
microservicio todavía no ha corrido. Levántalo una vez y vuelve a sembrar.

Por eso la semilla **no** vive en `compose/init-oracle/`: esos scripts corren
una sola vez, al crear la base, cuando ninguna tabla existe todavía.

## Cómo sembrar

```powershell
.\seed\sembrar.ps1
```

Es **idempotente**: se puede correr las veces que haga falta. Una empresa se
reconoce por su nombre, un usuario por su `azure_oid`, un servicio por
`(empresa, código)` y un repuesto por `(empresa, SKU)`. Volver a ejecutarlo no
duplica nada.

Si solo quieres una parte:

```powershell
.\seed\sembrar.ps1 -Solo usuarios
.\seed\sembrar.ps1 -Solo catalogo
```

## Qué queda cargado

**20 empresas** de mantención eléctrica, con nombres realistas de la zona.

**81 usuarios**: cuatro por empresa (`ADMIN`, `SUPERVISOR`, `CLIENTE`,
`AUDITOR`), más uno desactivado en la empresa 1 para poder probar que el sistema
rechaza a quien ya no trabaja ahí.

Los `azure_oid` son inventados y siguen el patrón `seed-empNN-rol`:

```
seed-emp01-admin        admin.emp01@digitalfix.cl
seed-emp01-supervisor   supervisor.emp01@digitalfix.cl
seed-emp03-auditor      auditor.emp03@digitalfix.cl
seed-emp01-desvinculado (activo = 0)
```

Cuando exista el tenant de identidad real (`T-02`), los usuarios de prueba se
crean allí y estos `oid` se reemplazan por los verdaderos.

**Catálogo de ejemplo** en las empresas 1, 2 y 3: cuatro servicios y cinco
repuestos cada una. `BRK-16A` queda con stock 3 y mínimo 5 **a propósito**: es
el caso que `HU-19` tiene que hacer visible apenas se abre la pantalla de
repuestos.

Tres empresas y no veinte porque con tres ya se demuestra lo único que hay que
demostrar aquí: que una empresa no ve lo de otra. Con veinte, la pantalla se
llena de ruido y la demostración se pierde.

## Para comprobar el aislamiento entre empresas

Con el catálogo levantado:

```powershell
# la empresa 1 ve sus servicios
Invoke-RestMethod http://localhost:8082/api/catalog/services `
  -Headers @{ "X-Company-Id"="1"; "X-User-Oid"="seed-emp01-admin"; "X-Roles"="ADMIN" }

# la empresa 2 ve los suyos, que son otros
Invoke-RestMethod http://localhost:8082/api/catalog/services `
  -Headers @{ "X-Company-Id"="2"; "X-User-Oid"="seed-emp02-admin"; "X-Roles"="ADMIN" }
```

Los identificadores no se repiten entre empresas, así que pedir por `id` un
servicio de otra empresa devuelve **404**, nunca 403: un 403 confirmaría que ese
recurso existe.
