-- =============================================================================
-- DigitalFix - catalogo de ejemplo para las tres primeras empresas.
-- =============================================================================
--
-- Corre DESPUES de que ms-digitalfix-catalog haya aplicado sus migraciones.
-- Se ejecuta como DFX_CATALOG.
--
--   .\seed\sembrar.ps1
--
-- Por que solo tres empresas y no las veinte: con tres alcanza para demostrar
-- lo unico que importa demostrar aqui, que una empresa no ve lo de otra. Con
-- veinte, la pantalla se llena de ruido y la demostracion se pierde.
--
-- Los COMPANY_ID son los de DFX_USUARIOS. No hay clave foranea entre esquemas
-- a proposito: cada microservicio es dueno del suyo y se comunican por HTTP o
-- por evento, nunca por join.
--
-- Idempotente: cada fila se reconoce por (COMPANY_ID, CODIGO) o (COMPANY_ID,
-- SKU), que son las claves unicas de negocio.
-- =============================================================================

SET SERVEROUTPUT ON

DECLARE
    TYPE t_ids IS TABLE OF NUMBER;
    v_empresas t_ids := t_ids(1, 2, 3);

    v_servicios NUMBER := 0;
    v_repuestos NUMBER := 0;
    v_relaciones NUMBER := 0;

    v_empresa   NUMBER;
    v_id_serv   NUMBER;
    v_id_rep    NUMBER;

    -- inserta un servicio si no existe, y devuelve su id
    FUNCTION servicio(p_empresa NUMBER, p_codigo VARCHAR2, p_nombre VARCHAR2,
                      p_desc VARCHAR2, p_tarifa NUMBER) RETURN NUMBER IS
        v_id NUMBER;
    BEGIN
        SELECT ID INTO v_id
          FROM SERVICE
         WHERE COMPANY_ID = p_empresa AND CODIGO = p_codigo;
        RETURN v_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO SERVICE (COMPANY_ID, CODIGO, NOMBRE, DESCRIPCION, TARIFA)
                 VALUES (p_empresa, p_codigo, p_nombre, p_desc, p_tarifa)
              RETURNING ID INTO v_id;
            RETURN v_id;
    END;

    -- inserta un repuesto si no existe, y devuelve su id
    FUNCTION repuesto(p_empresa NUMBER, p_sku VARCHAR2, p_nombre VARCHAR2,
                      p_stock NUMBER, p_minimo NUMBER, p_costo NUMBER) RETURN NUMBER IS
        v_id NUMBER;
    BEGIN
        SELECT ID INTO v_id
          FROM PART
         WHERE COMPANY_ID = p_empresa AND SKU = p_sku;
        RETURN v_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO PART (COMPANY_ID, SKU, NOMBRE, STOCK, STOCK_MINIMO, COSTO_UNITARIO)
                 VALUES (p_empresa, p_sku, p_nombre, p_stock, p_minimo, p_costo)
              RETURNING ID INTO v_id;
            RETURN v_id;
    END;

    PROCEDURE asociar(p_servicio NUMBER, p_repuesto NUMBER, p_cantidad NUMBER) IS
    BEGIN
        INSERT INTO SERVICE_PART (SERVICE_ID, PART_ID, CANTIDAD)
             VALUES (p_servicio, p_repuesto, p_cantidad);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN NULL;
    END;

BEGIN
    FOR i IN 1 .. v_empresas.COUNT LOOP
        v_empresa := v_empresas(i);

        -- ------------------------------------------------------------ servicios
        v_id_serv := servicio(v_empresa, 'SRV-001', 'Mantencion preventiva de tablero',
                              'Revision anual de tablero electrico y apriete de conexiones',
                              45000);
        DECLARE
            v_otro NUMBER;
        BEGIN
            v_otro := servicio(v_empresa, 'SRV-002', 'Termografia de tablero',
                               'Inspeccion termografica para detectar puntos calientes',
                               85000);
            v_otro := servicio(v_empresa, 'SRV-003', 'Cambio de interruptor automatico',
                               'Reemplazo de interruptor en tablero de distribucion',
                               32000);
            v_otro := servicio(v_empresa, 'SRV-004', 'Puesta a tierra: medicion y certificado',
                               'Medicion de resistencia de puesta a tierra con informe',
                               120000);
        END;

        -- ------------------------------------------------------------ repuestos
        -- BRK-16A queda bajo su minimo a proposito: es el caso que HU-19 tiene
        -- que hacer visible en cuanto se abre la pantalla
        v_id_rep := repuesto(v_empresa, 'BRK-16A', 'Interruptor automatico 16A', 3, 5, 8900);
        DECLARE
            v_otro NUMBER;
        BEGIN
            v_otro := repuesto(v_empresa, 'BRK-32A', 'Interruptor automatico 32A', 12, 4, 12400);
            v_otro := repuesto(v_empresa, 'CBL-25MM', 'Cable THHN 2.5mm (rollo 100m)', 8, 2, 34900);
            v_otro := repuesto(v_empresa, 'DIF-40A', 'Diferencial 40A 30mA', 2, 6, 21500);
            v_otro := repuesto(v_empresa, 'BOR-12', 'Bornera de 12 polos', 25, 5, 4300);
        END;

        -- --------------------------------------------------------- asociaciones
        asociar(v_id_serv, v_id_rep, 2);
    END LOOP;

    COMMIT;

    SELECT COUNT(*) INTO v_servicios  FROM SERVICE;
    SELECT COUNT(*) INTO v_repuestos  FROM PART;
    SELECT COUNT(*) INTO v_relaciones FROM SERVICE_PART;

    DBMS_OUTPUT.PUT_LINE('Servicios en el catalogo: ' || v_servicios);
    DBMS_OUTPUT.PUT_LINE('Repuestos en el catalogo: ' || v_repuestos);
    DBMS_OUTPUT.PUT_LINE('Asociaciones:             ' || v_relaciones);
END;
/

-- lo que tiene que ver cada empresa, y solo lo suyo
SELECT COMPANY_ID, COUNT(*) AS servicios FROM SERVICE GROUP BY COMPANY_ID ORDER BY COMPANY_ID;
SELECT COMPANY_ID, COUNT(*) AS repuestos,
       SUM(CASE WHEN STOCK <= STOCK_MINIMO THEN 1 ELSE 0 END) AS bajo_minimo
  FROM PART
 GROUP BY COMPANY_ID
 ORDER BY COMPANY_ID;
