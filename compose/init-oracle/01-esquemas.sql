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