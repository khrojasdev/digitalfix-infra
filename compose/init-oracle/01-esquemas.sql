-- DigitalFix - un esquema por microservicio.
--
-- Corre UNA SOLA VEZ, cuando el contenedor crea la base. Si necesitas volver a
-- ejecutarlo: docker compose -f compose/docker-compose.datos.yml down -v
--
-- La regla del proyecto es que cada microservicio es dueno exclusivo de su
-- esquema. Ningun servicio recibe permisos sobre el esquema de otro: las
-- referencias entre servicios se resuelven por HTTP o por evento, nunca con un
-- join entre esquemas.

ALTER SESSION SET CONTAINER = XEPDB1;

DECLARE
    TYPE t_lista IS TABLE OF VARCHAR2(30);
    v_esquemas t_lista := t_lista(
        'DFX_USUARIOS',
        'DFX_CATALOG',
        'DFX_WORKORDERS',
        'DFX_REPORT',
        'DFX_AUDIT'
    );
    v_clave VARCHAR2(60) := 'digitalfix';
    v_existe NUMBER;
BEGIN
    FOR i IN 1 .. v_esquemas.COUNT LOOP
        SELECT COUNT(*) INTO v_existe FROM dba_users WHERE username = v_esquemas(i);

        IF v_existe = 0 THEN
            EXECUTE IMMEDIATE 'CREATE USER ' || v_esquemas(i) ||
                              ' IDENTIFIED BY "' || v_clave || '"' ||
                              ' DEFAULT TABLESPACE USERS' ||
                              ' QUOTA UNLIMITED ON USERS';

            EXECUTE IMMEDIATE 'GRANT CREATE SESSION, CREATE TABLE, CREATE SEQUENCE, ' ||
                              'CREATE VIEW, CREATE PROCEDURE TO ' || v_esquemas(i);

            DBMS_OUTPUT.PUT_LINE('esquema creado: ' || v_esquemas(i));
        ELSE
            DBMS_OUTPUT.PUT_LINE('ya existia: ' || v_esquemas(i));
        END IF;
    END LOOP;
END;
/

-- La clave de desarrollo es la misma para los cinco a proposito: en local no
-- aporta nada tener cinco distintas y complica el arranque. En la nube (T-25)
-- cada esquema lleva su propia credencial, inyectada por variable de entorno.
