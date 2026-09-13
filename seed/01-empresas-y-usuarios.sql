-- =============================================================================
-- DigitalFix - datos semilla: 20 empresas y un usuario por rol en cada una.
-- =============================================================================
--
-- IMPORTANTE: este script corre DESPUES de que ms-digitalfix-usuarios haya
-- aplicado sus migraciones. No va en compose/init-oracle/ porque esos scripts
-- se ejecutan al crear la base, cuando las tablas todavia no existen.
--
--   .\seed\sembrar.ps1
--
-- Se ejecuta como DFX_USUARIOS y escribe en las tablas COMPANIA y APP_USER,
-- que son las que define la migracion V1 de ese microservicio.
--
-- Es idempotente: se puede correr las veces que haga falta. Una empresa se
-- reconoce por su nombre y un usuario por su azure_oid, asi que volver a
-- ejecutarlo no duplica nada.
--
-- Los oid son inventados y siguen el patron 'seed-empNN-rol'. Cuando exista el
-- tenant de identidad real (T-02), los usuarios de prueba se crean alli y estos
-- se reemplazan por sus oid verdaderos.
-- =============================================================================

SET SERVEROUTPUT ON

DECLARE
    TYPE t_lista IS TABLE OF VARCHAR2(100);

    -- 20 empresas de mantencion electrica, que es la red que describe el caso
    v_empresas t_lista := t_lista(
        'ElectroRed Valparaiso',
        'Mantenciones Alta Tension S.A.',
        'Servicios Electricos PyME',
        'Tableros y Control Quilpue',
        'Energia Segura Vina del Mar',
        'Montajes Electricos San Antonio',
        'Redes y Subestaciones Limache',
        'Ingenieria Electrica Casablanca',
        'Mantencion Industrial Concon',
        'Grupo Electrogeno Villa Alemana',
        'Instalaciones Los Andes',
        'Potencia y Control Rancagua',
        'Electricidad Integral Santiago Sur',
        'Servicios AT Maipu',
        'Redes Electricas Curico',
        'Mantenimiento Preventivo Talca',
        'Alta Tension Chillan',
        'Electro Austral Concepcion',
        'Servicios Energeticos Temuco',
        'Mantencion Electrica Puerto Montt'
    );

    -- los cuatro roles del caso
    v_roles t_lista := t_lista('ADMIN', 'SUPERVISOR', 'CLIENTE', 'AUDITOR');

    v_empresa_id   NUMBER;
    v_oid          VARCHAR2(50);
    v_empresas_nuevas NUMBER := 0;
    v_usuarios_nuevos NUMBER := 0;
    v_total_empresas  NUMBER := 0;
BEGIN
    FOR i IN 1 .. v_empresas.COUNT LOOP

        -- ---------------------------------------------------------- la empresa
        BEGIN
            SELECT id INTO v_empresa_id
              FROM compania
             WHERE nombre = v_empresas(i);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                INSERT INTO compania (nombre)
                     VALUES (v_empresas(i))
                  RETURNING id INTO v_empresa_id;
                v_empresas_nuevas := v_empresas_nuevas + 1;
        END;

        -- ------------------------------------------------- un usuario por rol
        FOR r IN 1 .. v_roles.COUNT LOOP
            v_oid := 'seed-emp' || LPAD(i, 2, '0') || '-' || LOWER(v_roles(r));

            BEGIN
                INSERT INTO app_user (azure_oid, email, nombre, rol, activo, compania_id)
                VALUES (
                    v_oid,
                    LOWER(v_roles(r)) || '.emp' || LPAD(i, 2, '0') || '@digitalfix.cl',
                    INITCAP(LOWER(v_roles(r))) || ' de ' || v_empresas(i),
                    v_roles(r),
                    1,
                    v_empresa_id
                );
                v_usuarios_nuevos := v_usuarios_nuevos + 1;
            EXCEPTION
                WHEN DUP_VAL_ON_INDEX THEN
                    NULL;  -- ya existe: el azure_oid es unico, el script es idempotente
            END;
        END LOOP;

    END LOOP;

    -- un usuario desactivado, para poder probar que el sistema lo rechaza
    BEGIN
        SELECT id INTO v_empresa_id FROM compania WHERE nombre = v_empresas(1);
        INSERT INTO app_user (azure_oid, email, nombre, rol, activo, compania_id)
        VALUES ('seed-emp01-desvinculado',
                'desvinculado.emp01@digitalfix.cl',
                'Tecnico desvinculado',
                'SUPERVISOR',
                0,
                v_empresa_id);
        v_usuarios_nuevos := v_usuarios_nuevos + 1;
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN NULL;
    END;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Empresas nuevas: ' || v_empresas_nuevas);
    DBMS_OUTPUT.PUT_LINE('Usuarios nuevos: ' || v_usuarios_nuevos);
    SELECT COUNT(*) INTO v_total_empresas FROM compania;
    DBMS_OUTPUT.PUT_LINE('Total empresas:  ' || v_total_empresas);
END;
/

-- resumen para confirmar a simple vista que quedo bien
SELECT c.id, c.nombre, COUNT(u.id) AS usuarios
  FROM compania c
  LEFT JOIN app_user u ON u.compania_id = c.id
 GROUP BY c.id, c.nombre
 ORDER BY c.id;
