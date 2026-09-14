-- =============================================================================
-- DigitalFix - datos de prueba del microservicio de CATALOGO
-- =============================================================================
--
-- CONECTARSE COMO:  DFX_CATALOG
--
--   sqlplus DFX_CATALOG/digitalfix@//localhost:1521/XEPDB1 @seed-catalogo.sql
--
-- O abrirlo en SQL Developer / DBeaver con esa conexion y ejecutarlo completo.
--
-- ANTES: ms-digitalfix-catalog tiene que haber arrancado al menos una vez, para
-- que Flyway haya creado SERVICE, PART y SERVICE_PART. Si sale ORA-00942 es eso.
--
-- QUE DEJA CARGADO, para las tres primeras empresas
--   4 servicios por empresa, con sus tarifas
--   5 repuestos por empresa, con su stock y su stock minimo
--   1 asociacion repuesto-servicio por empresa
--
-- Tres empresas y no veinte a proposito: con tres ya se demuestra lo unico que
-- hay que demostrar aqui, que una empresa no ve lo de otra. Con veinte, la
-- pantalla se llena de ruido y la demostracion se pierde.
--
-- EL REPUESTO BRK-16A QUEDA BAJO SU MINIMO A PROPOSITO (stock 3, minimo 5): es
-- el caso que HU-19 tiene que hacer visible apenas se abre la pantalla.
--
-- ES IDEMPOTENTE: cada fila se reconoce por su clave unica de negocio, que es
-- (COMPANY_ID, CODIGO) para los servicios y (COMPANY_ID, SKU) para los
-- repuestos. Volver a ejecutarlo no duplica nada.
-- =============================================================================

SET SERVEROUTPUT ON
SET DEFINE OFF

DECLARE
    TYPE t_ids IS TABLE OF NUMBER;

    -- Identificadores de empresa del esquema DFX_USUARIOS. No hay clave foranea
    -- entre esquemas a proposito: cada microservicio es dueno del suyo.
    v_empresas t_ids := t_ids(1, 2, 3);

    v_empresa    NUMBER;
    v_id_serv    NUMBER;
    v_id_rep     NUMBER;
    v_otro       NUMBER;

    v_servicios  NUMBER := 0;
    v_repuestos  NUMBER := 0;
    v_relaciones NUMBER := 0;
    v_bajo       NUMBER := 0;

    -- Inserta un servicio si no existe y devuelve su id.
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

    -- Inserta un repuesto si no existe y devuelve su id.
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
        v_id_serv := servicio(v_empresa, 'SRV-001',
                              'Mantencion preventiva de tablero',
                              'Revision anual de tablero electrico y apriete de conexiones',
                              45000);

        v_otro := servicio(v_empresa, 'SRV-002',
                           'Termografia de tablero',
                           'Inspeccion termografica para detectar puntos calientes',
                           85000);

        v_otro := servicio(v_empresa, 'SRV-003',
                           'Cambio de interruptor automatico',
                           'Reemplazo de interruptor en tablero de distribucion',
                           32000);

        v_otro := servicio(v_empresa, 'SRV-004',
                           'Puesta a tierra: medicion y certificado',
                           'Medicion de resistencia de puesta a tierra con informe',
                           120000);

        -- ------------------------------------------------------------ repuestos
        -- BRK-16A queda bajo su minimo a proposito
        v_id_rep := repuesto(v_empresa, 'BRK-16A', 'Interruptor automatico 16A',
                             3, 5, 8900);

        v_otro := repuesto(v_empresa, 'BRK-32A', 'Interruptor automatico 32A',
                           12, 4, 12400);
        v_otro := repuesto(v_empresa, 'CBL-25MM', 'Cable THHN 2.5mm (rollo 100m)',
                           8, 2, 34900);
        v_otro := repuesto(v_empresa, 'DIF-40A', 'Diferencial 40A 30mA',
                           2, 6, 21500);
        v_otro := repuesto(v_empresa, 'BOR-12', 'Bornera de 12 polos',
                           25, 5, 4300);

        -- --------------------------------------------------------- asociaciones
        asociar(v_id_serv, v_id_rep, 2);
    END LOOP;

    COMMIT;

    SELECT COUNT(*) INTO v_servicios  FROM SERVICE;
    SELECT COUNT(*) INTO v_repuestos  FROM PART;
    SELECT COUNT(*) INTO v_relaciones FROM SERVICE_PART;
    SELECT COUNT(*) INTO v_bajo       FROM PART WHERE STOCK <= STOCK_MINIMO;

    DBMS_OUTPUT.PUT_LINE('---------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Servicios en el catalogo : ' || v_servicios);
    DBMS_OUTPUT.PUT_LINE('Repuestos en el catalogo : ' || v_repuestos);
    DBMS_OUTPUT.PUT_LINE('Asociaciones             : ' || v_relaciones);
    DBMS_OUTPUT.PUT_LINE('Repuestos bajo su minimo : ' || v_bajo);
    DBMS_OUTPUT.PUT_LINE('---------------------------------------------');
END;
/

-- -----------------------------------------------------------------------------
-- Comprobacion: cada empresa tiene lo suyo y solo lo suyo.
-- -----------------------------------------------------------------------------
SELECT COMPANY_ID,
       COUNT(*) AS servicios
  FROM SERVICE
 GROUP BY COMPANY_ID
 ORDER BY COMPANY_ID;

SELECT COMPANY_ID,
       COUNT(*)                                                  AS repuestos,
       SUM(CASE WHEN STOCK <= STOCK_MINIMO THEN 1 ELSE 0 END)     AS bajo_minimo
  FROM PART
 GROUP BY COMPANY_ID
 ORDER BY COMPANY_ID;
