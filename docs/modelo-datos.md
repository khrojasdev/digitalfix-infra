# Modelo de datos · DigitalFix

Este documento define el modelo completo del sistema, no solo el del catálogo.
Se escribe antes que las migraciones para que cada microservicio pueda avanzar
sin bloquear a los demás y sin que después haya que rehacer esquemas.

## Regla que gobierna todo el modelo

**Cada microservicio es dueño exclusivo de su esquema.** Ningún servicio lee ni
escribe tablas de otro, y **no existen claves foráneas entre esquemas**. Cuando
un servicio necesita referirse a algo de otro, guarda el identificador suelto
(`NUMBER` o `VARCHAR2`) sin restricción referencial, y lo obtiene por HTTP o por
evento.

Esto tiene un costo que conviene asumir con los ojos abiertos: la base de datos
ya no garantiza la integridad de esas referencias. Si alguien borrara un servicio
del catálogo, las órdenes que lo referencian quedarían apuntando a un id que no
existe. Por eso **en el catálogo nada se borra: se desactiva** (`ACTIVO = 0`).

En este documento, las referencias entre esquemas están marcadas con **`↗`**.

| Esquema | Dueño | Tablas |
|---|---|---|
| `DFX_USUARIOS` | ms-digitalfix-usuarios | `COMPANY`, `APP_USER`, `APP_USER_ROL` |
| `DFX_CATALOG` | ms-digitalfix-catalog | `SERVICE`, `PART`, `SERVICE_PART`, `STOCK_MOVIMIENTO` |
| `DFX_WORKORDERS` | ms-digitalfix-workorders | `WORK_ORDER`, `ORDER_HISTORY`, `ORDER_PART` |
| `DFX_AUDIT` | ms-digitalfix-audit | `AUDIT_EVENT` |
| `DFX_REPORT` | ms-digitalfix-report | `KPI_ORDEN_HORA`, `KPI_ESTADO`, `KPI_RESOLUCION`, `RANKING_SERVICIO`, `EVENTO_PROCESADO` |
| — | ms-digitalfix-notify | sin base de datos (lo dice el caso) |

## Multi-empresa

Toda tabla que contenga datos de negocio lleva `COMPANY_ID`. La empresa **nunca**
llega desde el cliente: el BFF la resuelve desde `APP_USER` por el `oid` del
token y la propaga en la cabecera `X-Company-Id`. Cada repositorio filtra por ella
en la capa de datos, y pedir un recurso de otra empresa devuelve `404`, nunca
`403`, para no revelar que existe.

`COMPANY_ID` va **primero** en los índices compuestos, porque es el filtro que
aparece en todas las consultas.

---

## DFX_USUARIOS

### COMPANY

| Columna | Tipo | Restricciones |
|---|---|---|
| `ID` | `NUMBER` | PK, `GENERATED ALWAYS AS IDENTITY` |
| `RUT` | `VARCHAR2(12)` | `NOT NULL`, `UNIQUE` |
| `NOMBRE` | `VARCHAR2(120)` | `NOT NULL` |
| `ACTIVO` | `NUMBER(1)` | `DEFAULT 1`, `CHECK (ACTIVO IN (0,1))` |
| `CREADO_EN` | `TIMESTAMP` | `DEFAULT SYSTIMESTAMP NOT NULL` |

Las 20 empresas de la red son filas de esta tabla. No hay multi-tenancy de Azure:
un solo tenant de identidad, y la separación es por este `ID`.

### APP_USER

| Columna | Tipo | Restricciones |
|---|---|---|
| `ID` | `NUMBER` | PK, identidad |
| `AZURE_OID` | `VARCHAR2(64)` | `NOT NULL`, `UNIQUE` |
| `EMAIL` | `VARCHAR2(160)` | `NOT NULL` |
| `NOMBRE` | `VARCHAR2(120)` | |
| `COMPANY_ID` | `NUMBER` | `NOT NULL`, FK → `COMPANY(ID)` |
| `ACTIVO` | `NUMBER(1)` | `DEFAULT 1` |
| `CREADO_EN` | `TIMESTAMP` | `DEFAULT SYSTIMESTAMP NOT NULL` |
| `ULTIMO_INGRESO` | `TIMESTAMP` | |

Índice: `IDX_APP_USER_COMPANY (COMPANY_ID)`.

**`AZURE_OID` único es lo que hace idempotente la autoprovisión** (HU-04.3). El
alta al primer ingreso se hace con un `MERGE` sobre esta columna; si dos
peticiones del mismo usuario llegan a la vez, la segunda choca contra la
restricción y se resuelve leyendo la fila existente, no insertando otra.

### APP_USER_ROL

| Columna | Tipo | Restricciones |
|---|---|---|
| `APP_USER_ID` | `NUMBER` | PK compuesta, FK → `APP_USER(ID)` |
| `ROL` | `VARCHAR2(20)` | PK compuesta, `CHECK (ROL IN ('ADMIN','SUPERVISOR','CLIENTE','AUDITOR'))` |

Tabla aparte y no una columna en `APP_USER`, porque el token trae `roles` como
arreglo y un supervisor puede además ser cliente de otra empresa del grupo. Si el
equipo prefiere simplificar, se puede colapsar a una columna `ROL` en `APP_USER`
— pero entonces hay que fijar por contrato que el claim trae exactamente uno.

---

## DFX_CATALOG

Este es el esquema que se implementa ahora.

### SERVICE

| Columna | Tipo | Restricciones |
|---|---|---|
| `ID` | `NUMBER` | PK, identidad |
| `COMPANY_ID` | `NUMBER` | `NOT NULL` ↗ `DFX_USUARIOS.COMPANY` |
| `CODIGO` | `VARCHAR2(30)` | `NOT NULL` |
| `NOMBRE` | `VARCHAR2(120)` | `NOT NULL` |
| `DESCRIPCION` | `VARCHAR2(500)` | |
| `TARIFA` | `NUMBER(12,2)` | `NOT NULL`, `CHECK (TARIFA > 0)` |
| `ACTIVO` | `NUMBER(1)` | `DEFAULT 1` |
| `CREADO_EN` | `TIMESTAMP` | `DEFAULT SYSTIMESTAMP NOT NULL` |
| `ACTUALIZADO_EN` | `TIMESTAMP` | |

- `UK_SERVICE_CODIGO (COMPANY_ID, CODIGO)` — el código es único **por empresa**,
  no global. Dos empresas distintas pueden tener el código `MANT-01`. Esto es lo
  que devuelve `409` en HU-16.2.
- `IDX_SERVICE_COMPANY_ACTIVO (COMPANY_ID, ACTIVO)` — el listado de HU-13.2 y el
  selector de servicios activos.
- `CHECK (TARIFA > 0)` — la validación de HU-16.2 vive en la base además de en
  la aplicación, para que ningún camino la esquive.

### PART

| Columna | Tipo | Restricciones |
|---|---|---|
| `ID` | `NUMBER` | PK, identidad |
| `COMPANY_ID` | `NUMBER` | `NOT NULL` ↗ `DFX_USUARIOS.COMPANY` |
| `SKU` | `VARCHAR2(40)` | `NOT NULL` |
| `NOMBRE` | `VARCHAR2(120)` | `NOT NULL` |
| `STOCK` | `NUMBER(10)` | `DEFAULT 0 NOT NULL`, `CHECK (STOCK >= 0)` |
| `STOCK_MINIMO` | `NUMBER(10)` | `DEFAULT 0 NOT NULL`, `CHECK (STOCK_MINIMO >= 0)` |
| `COSTO_UNITARIO` | `NUMBER(12,2)` | `CHECK (COSTO_UNITARIO >= 0)` |
| `ACTIVO` | `NUMBER(1)` | `DEFAULT 1` |
| `CREADO_EN` | `TIMESTAMP` | `DEFAULT SYSTIMESTAMP NOT NULL` |
| `ACTUALIZADO_EN` | `TIMESTAMP` | |

- `UK_PART_SKU (COMPANY_ID, SKU)` — el `409` de HU-17.3.
- `IDX_PART_BAJO_MINIMO (COMPANY_ID, STOCK, STOCK_MINIMO)` — HU-19.1.
- `CHECK (STOCK >= 0)` es la red que garantiza el criterio *"nunca queda bajo
  cero"* de HU-17.3 aunque dos descuentos concurrentes se pisen.

### SERVICE_PART

| Columna | Tipo | Restricciones |
|---|---|---|
| `SERVICE_ID` | `NUMBER` | PK compuesta, FK → `SERVICE(ID)` |
| `PART_ID` | `NUMBER` | PK compuesta, FK → `PART(ID)` |
| `CANTIDAD` | `NUMBER(6)` | `NOT NULL`, `CHECK (CANTIDAD > 0)` |

La clave primaria compuesta es lo que hace idempotente la asociación de HU-18.2:
asociar dos veces el mismo par es un `MERGE` que actualiza la cantidad, no un
`INSERT` que duplica.

Ambas FK son válidas porque las dos tablas viven en el mismo esquema.

### STOCK_MOVIMIENTO

No la necesitas ahora — es de HU-24, en la fase de órdenes — pero va en el modelo
porque condiciona `PART`.

| Columna | Tipo | Restricciones |
|---|---|---|
| `ID` | `NUMBER` | PK, identidad |
| `PART_ID` | `NUMBER` | `NOT NULL`, FK → `PART(ID)` |
| `COMPANY_ID` | `NUMBER` | `NOT NULL` |
| `TIPO` | `VARCHAR2(15)` | `CHECK (TIPO IN ('RESERVA','REPOSICION'))` |
| `CANTIDAD` | `NUMBER(10)` | `NOT NULL`, `CHECK (CANTIDAD > 0)` |
| `WORK_ORDER_ID` | `NUMBER` | ↗ `DFX_WORKORDERS.WORK_ORDER` |
| `CLAVE_IDEMPOTENCIA` | `VARCHAR2(80)` | `NOT NULL`, `UNIQUE` |
| `CREADO_EN` | `TIMESTAMP` | `DEFAULT SYSTIMESTAMP NOT NULL` |

`CLAVE_IDEMPOTENCIA` única es el mecanismo del criterio *"reintentar la misma
asignación no descuenta el stock dos veces"* (HU-24.4): el segundo intento viola
la restricción y el servicio responde con el resultado del primero.

---

## DFX_WORKORDERS

### WORK_ORDER

| Columna | Tipo | Restricciones |
|---|---|---|
| `ID` | `NUMBER` | PK, identidad |
| `COMPANY_ID` | `NUMBER` | `NOT NULL` ↗ |
| `CODIGO` | `VARCHAR2(30)` | `NOT NULL` |
| `SERVICE_ID` | `NUMBER` | `NOT NULL` ↗ `DFX_CATALOG.SERVICE` |
| `CLIENTE_OID` | `VARCHAR2(64)` | `NOT NULL` ↗ `DFX_USUARIOS.APP_USER` |
| `TECNICO_OID` | `VARCHAR2(64)` | ↗ `DFX_USUARIOS.APP_USER` |
| `TITULO` | `VARCHAR2(160)` | `NOT NULL` |
| `DESCRIPCION` | `VARCHAR2(2000)` | `NOT NULL` |
| `DIRECCION` | `VARCHAR2(250)` | `NOT NULL` |
| `PRIORIDAD` | `VARCHAR2(10)` | `CHECK (PRIORIDAD IN ('BAJA','MEDIA','ALTA'))` |
| `ESTADO` | `VARCHAR2(20)` | `NOT NULL`, `CHECK (ESTADO IN ('CREADA','ASIGNADA','EN_DESPLAZAMIENTO','EN_EJECUCION','CERRADA','CANCELADA'))` |
| `CREADO_EN` | `TIMESTAMP` | `DEFAULT SYSTIMESTAMP NOT NULL` |
| `ASIGNADO_EN` | `TIMESTAMP` | |
| `CERRADO_EN` | `TIMESTAMP` | |
| `MOTIVO_CANCELACION` | `VARCHAR2(500)` | |
| `MINUTOS_RESOLUCION` | `NUMBER(10)` | |

- `UK_ORDEN_CODIGO (COMPANY_ID, CODIGO)`
- `IDX_ORDEN_LISTADO (COMPANY_ID, ESTADO, CREADO_EN DESC)` — el filtro de HU-21.
- `IDX_ORDEN_CLIENTE (COMPANY_ID, CLIENTE_OID, CREADO_EN DESC)` — HU-27.
- `MINUTOS_RESOLUCION` se calcula y se guarda al cerrar (HU-26), no se computa en
  cada consulta.

### ORDER_HISTORY

| Columna | Tipo | Restricciones |
|---|---|---|
| `ID` | `NUMBER` | PK, identidad |
| `WORK_ORDER_ID` | `NUMBER` | `NOT NULL`, FK → `WORK_ORDER(ID)` |
| `ESTADO_ANTERIOR` | `VARCHAR2(20)` | |
| `ESTADO_NUEVO` | `VARCHAR2(20)` | `NOT NULL` |
| `AUTOR_OID` | `VARCHAR2(64)` | `NOT NULL` ↗ |
| `NOTA` | `VARCHAR2(500)` | |
| `CORRELATION_ID` | `VARCHAR2(64)` | |
| `CREADO_EN` | `TIMESTAMP` | `DEFAULT SYSTIMESTAMP NOT NULL` |

Índice `IDX_HIST_ORDEN (WORK_ORDER_ID, CREADO_EN)`. Se escribe **en la misma
transacción** que el cambio de estado: si falla el historial, el cambio se
revierte.

### ORDER_PART

Instantánea de los repuestos comprometidos al asignar el técnico. Guarda una
copia del `SKU` y del nombre para que el detalle histórico de la orden siga
siendo legible aunque el repuesto cambie o se desactive en el catálogo.

| Columna | Tipo | Restricciones |
|---|---|---|
| `ID` | `NUMBER` | PK, identidad |
| `WORK_ORDER_ID` | `NUMBER` | `NOT NULL`, FK → `WORK_ORDER(ID)` |
| `PART_ID` | `NUMBER` | `NOT NULL` ↗ `DFX_CATALOG.PART` |
| `SKU` | `VARCHAR2(40)` | `NOT NULL` (copia) |
| `NOMBRE` | `VARCHAR2(120)` | (copia) |
| `CANTIDAD` | `NUMBER(6)` | `NOT NULL`, `CHECK (CANTIDAD > 0)` |

---

## DFX_AUDIT

### AUDIT_EVENT

Bitácora de solo inserción. La aplicación **no expone ninguna operación de
modificación ni de borrado** (HU-45.2), y el usuario de base de datos del
microservicio solo tiene `INSERT` y `SELECT` sobre esta tabla.

| Columna | Tipo | Restricciones |
|---|---|---|
| `ID` | `NUMBER` | PK, identidad |
| `EVENT_ID` | `VARCHAR2(64)` | `NOT NULL`, `UNIQUE` |
| `TIPO` | `VARCHAR2(30)` | `NOT NULL` |
| `WORK_ORDER_ID` | `NUMBER` | ↗ |
| `COMPANY_ID` | `NUMBER` | `NOT NULL` ↗ |
| `AUTOR_OID` | `VARCHAR2(64)` | ↗ |
| `OCURRIDO_EN` | `TIMESTAMP` | `NOT NULL` |
| `RECIBIDO_EN` | `TIMESTAMP` | `DEFAULT SYSTIMESTAMP NOT NULL` |
| `CORRELATION_ID` | `VARCHAR2(64)` | |
| `PAYLOAD` | `CLOB` | |

`EVENT_ID` único es lo que cumple *"reprocesar el historial completo no duplica
eventos"* (HU-45.1). `OCURRIDO_EN` es cuándo pasó en origen; `RECIBIDO_EN` es
cuándo lo consumió auditoría — la diferencia entre ambas es el rezago de HU-46.1.

Índices: `(COMPANY_ID, OCURRIDO_EN DESC)`, `(AUTOR_OID)`, `(TIPO)`. Los tres
salen directo de los filtros que pide HU-44.

---

## DFX_REPORT

Modelo de lectura. Se construye consumiendo eventos, **nunca consultando las
tablas de la operación en vivo** (HU-42.3). Si este esquema se cae o se atrasa,
crear y cerrar órdenes sigue funcionando.

| Tabla | Clave primaria | Columnas |
|---|---|---|
| `KPI_ORDEN_HORA` | `(FECHA_HORA, COMPANY_ID)` | `CANTIDAD` |
| `KPI_ESTADO` | `(FECHA, COMPANY_ID, ESTADO)` | `CANTIDAD` |
| `KPI_RESOLUCION` | `(FECHA, COMPANY_ID)` | `TOTAL_ORDENES`, `SUMA_MINUTOS` |
| `RANKING_SERVICIO` | `(FECHA, COMPANY_ID, SERVICE_ID)` | `NOMBRE_SERVICIO`, `CANTIDAD` |
| `EVENTO_PROCESADO` | `EVENT_ID` | `PROCESADO_EN` |

`KPI_RESOLUCION` guarda **suma y total, no el promedio**. El promedio se calcula
al leer. Guardar el promedio haría imposible agregarlo entre períodos sin error.

`RANKING_SERVICIO` copia `NOMBRE_SERVICIO` porque no puede hacer join contra el
catálogo. `EVENTO_PROCESADO` es el control de idempotencia del consumidor.

---

## ms-digitalfix-notify

Sin base de datos, como dice el caso. El estado de los avisos vive en las colas
de RabbitMQ y en sus colas de descarte. Los informes técnicos en PDF (HU-36) se
guardan en un volumen montado, con el nombre derivado del código de la orden.

---

## Convenciones

- **Nombres**: tablas y columnas en `MAYUSCULA_CON_GUION_BAJO`, sin acentos.
- **Claves primarias**: `NUMBER GENERATED ALWAYS AS IDENTITY`, salvo las
  compuestas de las tablas de relación.
- **Marcas de tiempo**: `TIMESTAMP` con `DEFAULT SYSTIMESTAMP`. Todo en UTC.
- **Booleanos**: `NUMBER(1)` con `CHECK IN (0,1)`; Oracle no tiene `BOOLEAN` en
  columnas de tabla.
- **Dinero**: `NUMBER(12,2)`. Nunca coma flotante.
- **Borrado**: no se borra. Se desactiva con `ACTIVO = 0`.
- **Migraciones**: Flyway, `V<n>__<descripcion>.sql`, una por tarea del tablero.
  Nunca se edita una migración ya mergeada: se agrega otra.
