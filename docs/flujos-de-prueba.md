# Funcionalidades y flujos a probar - DigitalFix

Plan de pruebas manuales de punta a punta: qué funcionalidad se prueba, con qué rol, los pasos y el resultado esperado. Complementa a `matriz-pruebas.md`, que lista las pruebas automatizadas.

**64 flujos** en 13 áreas. Marca cada uno al probarlo: ✅ funciona · ❌ falla · ⚠️ funciona con observaciones.

## Antes de empezar

- Un usuario de prueba por rol (ADMIN, SUPERVISOR, CLIENTE, AUDITOR) con el app role asignado en Entra ID y su fila en APP_USER (azure_oid, rol, compania_id, activo = 1).
- Al menos dos empresas con datos, para probar el aislamiento entre empresas.
- Catálogo con servicios activos e inactivos, y repuestos con alguno bajo su stock mínimo.
- Frontend reconstruido desde main (no hay CI: la imagen se construye a mano) y BFF con el arreglo de rutas de órdenes, reportes y auditoría.
- RabbitMQ (rabbitmq1 y rabbitmq2) arriba, con los consumidores de audit, report y notify conectados.

## Permisos esperados por rol

| Pantalla | ADMIN | SUPERVISOR | CLIENTE | AUDITOR |
|---|---|---|---|---|
| Panel | ✅ | ✅ | — | ✅ |
| Catálogo de servicios | ✅ | ✅ | ✅ | ✅ |
| Repuestos | ✅ | ✅ | — | ✅ |
| Órdenes: ver | ✅ | ✅ | ✅ | ✅ |
| Órdenes: crear | ✅ | ✅ | ✅ | — |
| Órdenes: cambiar estado | ✅ | ✅ | — | — |
| Reportes | ✅ | ✅* | — | — |
| Auditoría | ✅ | — | — | ✅ |
| Notificaciones | ✅ | ✅ | — | ✅ |

\* Ver hallazgos: hoy ms-digitalfix-report responde 403 al SUPERVISOR.

## A. Autenticación y sesión

| ID | Flujo | Rol | Pasos | Resultado esperado | Estado |
|---|---|---|---|---|---|
| A1 | Inicio de sesión | Todos | Abrir la app sin sesión → Iniciar sesión → autenticarse en Microsoft. | Vuelve a la app, entra al catálogo y la cabecera muestra nombre y empresa. | |
| A2 | Perfil desde /api/me | Todos | F12 → Network → recargar la página (sin escribir la URL). | Aparece GET /api/me tipo fetch/xhr, con authorization: Bearer, status 200 y roles en el JSON. | |
| A3 | Cerrar sesión | Todos | Botón Cerrar sesión. | Cierra la sesión en Microsoft y vuelve a la pantalla de inicio. | |
| A4 | Ruta protegida sin sesión | — | Sin sesión, abrir /workorders directamente. | Redirige a /login. | |
| A5 | Modo oscuro | Todos | Botón de luna/sol en la barra superior → recargar la página. | Cambia a oscuro/claro y la elección se mantiene al recargar. | |
| A6 | Crear cuenta | — | En /login, Crear cuenta. | Redirige al flujo de registro de Microsoft. | |

## B. Autorización por rol

| ID | Flujo | Rol | Pasos | Resultado esperado | Estado |
|---|---|---|---|---|---|
| B1 | Menú según rol | Cada rol | Entrar con cada usuario de prueba. | El menú lateral muestra solo las pantallas de la matriz de permisos. | |
| B2 | Acceso directo por URL | CLIENTE | Escribir /reports o /audit en la barra. | Muestra Acceso denegado, no la pantalla. | |
| B3 | AUDITOR solo lectura en órdenes | AUDITOR | Abrir Órdenes de trabajo. | Ve la lista pero no el botón Nueva orden ni el botón Estado. | |
| B4 | CLIENTE crea pero no gestiona | CLIENTE | Abrir Órdenes de trabajo. | Ve Nueva orden; no ve el botón Estado. | |
| B5 | BFF rechaza sin rol | CLIENTE | Llamar /api/audit/events con su token (Postman/curl). | 403 del BFF. | |

## C. Multiempresa

| ID | Flujo | Rol | Pasos | Resultado esperado | Estado |
|---|---|---|---|---|---|
| C1 | Aislamiento de datos | ADMIN de 2 empresas | Entrar con un ADMIN de cada empresa y comparar catálogo, órdenes y auditoría. | Cada uno ve solo los datos de su empresa. | |
| C2 | Recurso de otra empresa | ADMIN | Cambiar estado de una orden de otra empresa (PUT con su id). | 404, no 403: no revela que exista. | |

## D. Catálogo de servicios

| ID | Flujo | Rol | Pasos | Resultado esperado | Estado |
|---|---|---|---|---|---|
| D1 | Listar | ADMIN | Abrir Catálogo. | Lista paginada con código, nombre, descripción, tarifa y estado. | |
| D2 | Crear servicio | ADMIN | Nuevo servicio → completar → Guardar. | Aparece en la lista con mensaje de confirmación. | |
| D3 | Código duplicado | ADMIN | Crear un servicio con un código que ya existe. | Mensaje de error 409, no se crea. | |
| D4 | Editar | ADMIN | Lápiz → cambiar tarifa → Guardar. | La tarifa se actualiza en la lista. | |
| D5 | Dar de baja | ADMIN | Botón bloquear → ¿Dar de baja? → Sí. | Desaparece con Solo activos encendido. | |
| D6 | Reactivar | ADMIN | Apagar Solo activos → botón reactivar en un inactivo. | Vuelve a estado Activo. | |
| D7 | Buscar | Todos | Escribir parte del nombre, código o descripción (con o sin tildes). | Solo quedan los que coinciden y se muestra cuántos. | |
| D8 | Rango de tarifa | Todos | Tarifa mínima y máxima. | Solo servicios dentro del rango (inclusive). | |
| D9 | Paginación | Todos | Cambiar a 10 por página y avanzar. | Pide la página al servidor y muestra el rango correcto. | |

## E. Repuestos e inventario

| ID | Flujo | Rol | Pasos | Resultado esperado | Estado |
|---|---|---|---|---|---|
| E1 | Listar | ADMIN | Abrir Repuestos. | Lista con SKU, nombre, stock, mínimo y costo. | |
| E2 | Bajo mínimo resaltado | ADMIN | Revisar repuestos con stock ≤ mínimo. | Fila en rojo, ícono de alerta y aviso con la cantidad. | |
| E3 | Solo bajo mínimo | ADMIN | Encender Solo bajo mínimo. | Lista solo los críticos (consulta /low-stock). | |
| E4 | Crear / editar / desactivar | ADMIN | Nuevo repuesto, editar uno y desactivarlo. | Cada acción se refleja en la lista. | |
| E5 | Buscar y filtrar estado | ADMIN | Buscar por SKU; filtrar Activos / Inactivos. | La lista se reduce a lo que coincide. | |
| E6 | Exportar CSV | ADMIN | Exportar CSV. | Descarga un CSV que abre bien en Excel (tildes y columnas). | |
| E7 | Alerta de stock → notificación | ADMIN | Editar un repuesto dejándolo bajo su mínimo. | Llega un aviso a Notificaciones › Stock bajo mínimo. | |

## F. Órdenes de trabajo

| ID | Flujo | Rol | Pasos | Resultado esperado | Estado |
|---|---|---|---|---|---|
| F1 | Crear orden | ADMIN / SUPERVISOR / CLIENTE | Nueva orden → elegir servicio → comentario → Crear orden. | Aparece primera en la lista en estado Creada; aviso de confirmación. | |
| F2 | Validación | ADMIN | Intentar crear sin elegir servicio. | El botón queda deshabilitado; no se envía nada. | |
| F3 | Flujo de estados | ADMIN / SUPERVISOR | Estado → Asignada → En curso → Cerrada. | Cada cambio se ve en la fila y en los indicadores. | |
| F4 | Cancelar | ADMIN / SUPERVISOR | En una orden abierta, Estado → Cancelada. | Pasa a Cancelada. | |
| F5 | Orden terminada | ADMIN | Revisar una orden Cerrada o Cancelada. | No ofrece el botón Estado. | |
| F6 | Filtros | Todos | Buscar por n.° de orden o servicio; filtrar por estado, servicio y fechas. | Se combinan y se muestra cuántas coinciden. | |
| F7 | Paginación y CSV | Todos | Cambiar tamaño de página; Exportar CSV. | Pagina bien; el CSV trae lo filtrado. | |
| F8 | Indicadores | Todos | Comparar Total/Abiertas/Cerradas/Canceladas con la lista. | Los números calzan con las filas. | |

## G. Mensajería (RabbitMQ)

| ID | Flujo | Rol | Pasos | Resultado esperado | Estado |
|---|---|---|---|---|---|
| G1 | Orden creada → auditoría | ADMIN | Crear una orden y abrir Auditoría. | Aparece un evento Creada con ese n.° de orden. | |
| G2 | Cambio de estado → audit, report y notify | ADMIN | Cambiar el estado de una orden. | Evento en Auditoría, aviso en Notificaciones y conteo actualizado en Reportes. | |
| G3 | Mensaje inválido → DLQ | Técnico | Publicar un mensaje mal formado en la cola (panel de RabbitMQ). | Termina en la cola .dlq, no se reintenta en bucle. | |
| G4 | Idempotencia | Técnico | Reenviar el mismo mensaje (misma eventKey). | No se duplica el registro. | |
| G5 | Broker caído | Técnico | Detener RabbitMQ y crear una orden. | La orden se crea igual (publicación resiliente) y queda registrado el error. | |
| G6 | Cluster de 2 nodos | Técnico | Detener rabbitmq1. | rabbitmq2 sigue atendiendo. | |

## H. Notificaciones

| ID | Flujo | Rol | Pasos | Resultado esperado | Estado |
|---|---|---|---|---|---|
| H1 | Ver avisos | ADMIN | Abrir Notificaciones. | Indicadores y dos listas (cambios de estado y stock), lo más reciente primero. | |
| H2 | Filtros | ADMIN | Buscar texto; filtrar por evento y fechas. | Ambas listas se reducen a lo que coincide. | |

## I. Reportes

| ID | Flujo | Rol | Pasos | Resultado esperado | Estado |
|---|---|---|---|---|---|
| I1 | Indicadores por período | ADMIN | Elegir 24 horas, 7 días y 30 días. | Cambian órdenes, abiertas, tasa de cierre y tiempo medio. | |
| I2 | Gráficos | ADMIN | Revisar Órdenes por estado y Servicios más solicitados. | Barras proporcionales, con nombre de servicio. | |
| I3 | Descargar PDF | ADMIN | Descargar PDF. | PDF con encabezado, empresa, período, indicadores, estados, ranking y n.° de página. | |
| I4 | Descargar CSV | ADMIN | Descargar CSV. | CSV con el período, indicadores, estados y ranking. | |
| I5 | SUPERVISOR | SUPERVISOR | Abrir Reportes. | Hoy: mensaje 403 (ms-report exige ADMIN). Ver hallazgos. | |

## J. Auditoría

| ID | Flujo | Rol | Pasos | Resultado esperado | Estado |
|---|---|---|---|---|---|
| J1 | Listar | ADMIN / AUDITOR | Abrir Auditoría. | Eventos paginados, el más reciente primero. | |
| J2 | Filtros en servidor | AUDITOR | Filtrar por tipo, autor (oid) y fechas → Buscar. | La consulta lleva los parámetros y vuelve a la página 1. | |
| J3 | Filtrar por autor con un clic | AUDITOR | Clic en el oid de una fila. | Muestra solo los eventos de ese autor. | |
| J4 | Paginación real | AUDITOR | Avanzar páginas. | El total es el del servidor, no el de la página. | |
| J5 | Sin permiso | SUPERVISOR | Abrir /audit por URL. | Acceso denegado. | |

## K. Panel

| ID | Flujo | Rol | Pasos | Resultado esperado | Estado |
|---|---|---|---|---|---|
| K1 | Indicadores | ADMIN | Abrir Panel. | Seis indicadores con datos reales y saludo con nombre y empresa. | |
| K2 | Resiliencia | ADMIN | Detener ms-workorders y abrir Panel. | El panel se ve; la parte de órdenes muestra que no se pudo cargar. | |

## L. Despliegue e infraestructura

| ID | Flujo | Rol | Pasos | Resultado esperado | Estado |
|---|---|---|---|---|---|
| L1 | Cadena de red | Técnico | Navegador → API Gateway → nginx → BFF. | Gateway /{proxy+} a nginx:80; nginx proxya /api/ al BFF:8080. | |
| L2 | BFF responde | Técnico | En el EC2: curl -i http://localhost:8080/api/me | 401 Token ausente o inválido (el endpoint existe). | |
| L3 | Imagen del front al día | Técnico | docker ps / docker images del front. | Fecha posterior al último merge a main. | |
| L4 | Salud de servicios | Técnico | GET /actuator/health de cada servicio. | UP. | |

## M. No funcionales

| ID | Flujo | Rol | Pasos | Resultado esperado | Estado |
|---|---|---|---|---|---|
| M1 | Responsive | Todos | Abrir en el celular (o ancho 390 px). | Menú oculto con botón, una columna, sin scroll horizontal de la página. | |
| M2 | Teclado | Todos | Navegar con Tab. | El foco siempre visible. | |
| M3 | Carga del PDF | ADMIN | Revisar Network al entrar a la app. | jsPDF no se descarga hasta generar el PDF. | |

## Hallazgos conocidos

Puntos detectados al revisar el código, para decidir o corregir:

- Reportes: el BFF y el menú permiten SUPERVISOR, pero ms-digitalfix-report exige ADMIN (exigirEmpresaAdmin). Hay que decidir si el SUPERVISOR debe ver reportes y alinear uno de los dos lados.
- Transiciones de estado: el frontend solo ofrece las válidas, pero ms-digitalfix-workorders acepta cualquier cambio. Conviene validarlo también en el backend.
- Catálogo: la búsqueda y el rango de tarifa filtran la página cargada (el backend no acepta búsqueda). Con catálogos grandes, subir el tamaño de página o agregar el filtro al backend.
- El BFF corre con el perfil local (modo-desarrollo: true): entrega un contexto por defecto si el oid no está en APP_USER. Para producción, desactivarlo.
- No hay CI/CD en el frontend: cada merge a main requiere reconstruir y redeplegar la imagen a mano.
