# Diagrama entidad-relación

Cada bloque es un esquema distinto, propiedad de un microservicio. Las líneas
punteadas del final son referencias entre esquemas: se guardan como identificador
suelto, **sin clave foránea**.

## DFX_USUARIOS

```mermaid
erDiagram
    COMPANY ||--o{ APP_USER : "emplea a"
    APP_USER ||--o{ APP_USER_ROL : "tiene"

    COMPANY {
        NUMBER ID PK
        VARCHAR2 RUT UK
        VARCHAR2 NOMBRE
        NUMBER ACTIVO
        TIMESTAMP CREADO_EN
    }
    APP_USER {
        NUMBER ID PK
        VARCHAR2 AZURE_OID UK
        VARCHAR2 EMAIL
        VARCHAR2 NOMBRE
        NUMBER COMPANY_ID FK
        NUMBER ACTIVO
        TIMESTAMP CREADO_EN
        TIMESTAMP ULTIMO_INGRESO
    }
    APP_USER_ROL {
        NUMBER APP_USER_ID PK
        VARCHAR2 ROL PK
    }
```

## DFX_CATALOG

```mermaid
erDiagram
    SERVICE ||--o{ SERVICE_PART : "requiere"
    PART ||--o{ SERVICE_PART : "se usa en"
    PART ||--o{ STOCK_MOVIMIENTO : "registra"

    SERVICE {
        NUMBER ID PK
        NUMBER COMPANY_ID "ref externa"
        VARCHAR2 CODIGO UK
        VARCHAR2 NOMBRE
        VARCHAR2 DESCRIPCION
        NUMBER TARIFA
        NUMBER ACTIVO
        TIMESTAMP CREADO_EN
        TIMESTAMP ACTUALIZADO_EN
    }
    PART {
        NUMBER ID PK
        NUMBER COMPANY_ID "ref externa"
        VARCHAR2 SKU UK
        VARCHAR2 NOMBRE
        NUMBER STOCK
        NUMBER STOCK_MINIMO
        NUMBER COSTO_UNITARIO
        NUMBER ACTIVO
        TIMESTAMP CREADO_EN
        TIMESTAMP ACTUALIZADO_EN
    }
    SERVICE_PART {
        NUMBER SERVICE_ID PK
        NUMBER PART_ID PK
        NUMBER CANTIDAD
    }
    STOCK_MOVIMIENTO {
        NUMBER ID PK
        NUMBER PART_ID FK
        NUMBER COMPANY_ID
        VARCHAR2 TIPO
        NUMBER CANTIDAD
        NUMBER WORK_ORDER_ID "ref externa"
        VARCHAR2 CLAVE_IDEMPOTENCIA UK
        TIMESTAMP CREADO_EN
    }
```

## DFX_WORKORDERS

```mermaid
erDiagram
    WORK_ORDER ||--o{ ORDER_HISTORY : "registra"
    WORK_ORDER ||--o{ ORDER_PART : "compromete"

    WORK_ORDER {
        NUMBER ID PK
        NUMBER COMPANY_ID "ref externa"
        VARCHAR2 CODIGO UK
        NUMBER SERVICE_ID "ref externa"
        VARCHAR2 CLIENTE_OID "ref externa"
        VARCHAR2 TECNICO_OID "ref externa"
        VARCHAR2 TITULO
        VARCHAR2 DESCRIPCION
        VARCHAR2 DIRECCION
        VARCHAR2 PRIORIDAD
        VARCHAR2 ESTADO
        TIMESTAMP CREADO_EN
        TIMESTAMP ASIGNADO_EN
        TIMESTAMP CERRADO_EN
        VARCHAR2 MOTIVO_CANCELACION
        NUMBER MINUTOS_RESOLUCION
    }
    ORDER_HISTORY {
        NUMBER ID PK
        NUMBER WORK_ORDER_ID FK
        VARCHAR2 ESTADO_ANTERIOR
        VARCHAR2 ESTADO_NUEVO
        VARCHAR2 AUTOR_OID "ref externa"
        VARCHAR2 NOTA
        VARCHAR2 CORRELATION_ID
        TIMESTAMP CREADO_EN
    }
    ORDER_PART {
        NUMBER ID PK
        NUMBER WORK_ORDER_ID FK
        NUMBER PART_ID "ref externa"
        VARCHAR2 SKU
        VARCHAR2 NOMBRE
        NUMBER CANTIDAD
    }
```

## DFX_AUDIT y DFX_REPORT

```mermaid
erDiagram
    AUDIT_EVENT {
        NUMBER ID PK
        VARCHAR2 EVENT_ID UK
        VARCHAR2 TIPO
        NUMBER WORK_ORDER_ID "ref externa"
        NUMBER COMPANY_ID "ref externa"
        VARCHAR2 AUTOR_OID "ref externa"
        TIMESTAMP OCURRIDO_EN
        TIMESTAMP RECIBIDO_EN
        VARCHAR2 CORRELATION_ID
        CLOB PAYLOAD
    }
    KPI_ORDEN_HORA {
        TIMESTAMP FECHA_HORA PK
        NUMBER COMPANY_ID PK
        NUMBER CANTIDAD
    }
    KPI_ESTADO {
        DATE FECHA PK
        NUMBER COMPANY_ID PK
        VARCHAR2 ESTADO PK
        NUMBER CANTIDAD
    }
    KPI_RESOLUCION {
        DATE FECHA PK
        NUMBER COMPANY_ID PK
        NUMBER TOTAL_ORDENES
        NUMBER SUMA_MINUTOS
    }
    RANKING_SERVICIO {
        DATE FECHA PK
        NUMBER COMPANY_ID PK
        NUMBER SERVICE_ID PK
        VARCHAR2 NOMBRE_SERVICIO
        NUMBER CANTIDAD
    }
    EVENTO_PROCESADO {
        VARCHAR2 EVENT_ID PK
        TIMESTAMP PROCESADO_EN
    }
```

## Referencias entre esquemas

```mermaid
flowchart LR
    subgraph U["DFX_USUARIOS"]
        COMPANY
        APP_USER
    end
    subgraph C["DFX_CATALOG"]
        SERVICE
        PART
    end
    subgraph W["DFX_WORKORDERS"]
        WORK_ORDER
        ORDER_PART
    end
    subgraph A["DFX_AUDIT"]
        AUDIT_EVENT
    end
    subgraph R["DFX_REPORT"]
        KPIS["tablas KPI"]
    end

    SERVICE -. COMPANY_ID .-> COMPANY
    PART -. COMPANY_ID .-> COMPANY
    WORK_ORDER -. SERVICE_ID .-> SERVICE
    WORK_ORDER -. CLIENTE_OID / TECNICO_OID .-> APP_USER
    ORDER_PART -. PART_ID .-> PART
    AUDIT_EVENT -. WORK_ORDER_ID .-> WORK_ORDER
    KPIS -. por eventos .-> WORK_ORDER
```
