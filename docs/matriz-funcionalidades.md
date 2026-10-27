# Matriz de funcionalidades - DigitalFix

Alcance del proyecto (caso DigitalFix y pauta EP3) con el estado de cada
funcionalidad, el componente responsable y una evidencia verificable:
endpoint, clase, prueba automatizada o Pull Request. El estado considera la
rama `main` de cada repositorio más los Pull Requests de esta entrega,
listados al final.

**Estados:** `Implementada` · `Parcial` · `Pendiente`

## 1. Autenticación, identidad y roles

| # | Funcionalidad | Componente | Estado | Evidencia |
|---|---|---|---|---|
| 1 | Login corporativo con Entra ID (OIDC + PKCE) | frontend | Implementada | MSAL en `core/auth`, flujo por redirección |
| 2 | Validación del JWT (firma, emisor, audiencia, vigencia) | bff | Implementada | `SecurityConfig`, `AudienceValidator` |
| 3 | Autorización por rol en cada ruta | bff | Implementada | `SecurityConfig` `hasAnyRole(...)`, pruebas de matriz de roles |
| 4 | Resolución de empresa por `oid` (APP_USER) | bff + usuarios | Implementada | `ResolutorPorJwt`, `GET /api/users/{oid}` |
| 5 | Propagación de contexto (`X-User-Oid`, `X-Company-Id`, `X-Roles`, `X-User-Email`, `X-User-Name`) | bff | Implementada | `ContextoUsuarioFilter`, `ClienteWorkorders` (bff #230) |
| 6 | Correlación extremo a extremo (`X-Correlation-Id`) | bff + todos | Implementada | `CorrelacionSaliente`, `CorrelacionSalienteTest` (bff #230) |
| 7 | Rol del tenant sincronizado en cada inicio de sesión (sin asignarlo dos veces) | usuarios + bff | Implementada | `AppUserService.autoProvision`, `SincronizacionConElTenantTest` (usuarios #22), `/api/me` (bff #230) |
| 8 | Menú y rutas protegidas por rol | frontend | Implementada | `app.routes.ts` con guardas, `layout.component.spec` |

## 2. Usuarios (ms-digitalfix-usuarios)

| # | Funcionalidad | Componente | Estado | Evidencia |
|---|---|---|---|---|
| 9 | Autoaprovisionamiento al primer ingreso | usuarios | Implementada | `POST /api/users/login` |
| 10 | Listar usuarios de la empresa | usuarios | Implementada | `GET /api/users` |
| 11 | Obtener usuario por `oid` | usuarios | Implementada | `GET /api/users/{oid}` |
| 12 | Activar / desactivar usuario | usuarios | Implementada | `PUT /api/users/{oid}/status` |
| 13 | Eliminar usuario | usuarios | Implementada | `DELETE /api/users/{oid}` |
| 14 | Eventos de usuario (creado, estado, rol cambiado) | usuarios | Implementada | `UsuarioEventoPublisher`, `usuarios.negocio.exchange` (usuarios #22) |

## 3. Catálogo y stock (ms-digitalfix-catalog)

| # | Funcionalidad | Componente | Estado | Evidencia |
|---|---|---|---|---|
| 15 | CRUD de servicios | catalog | Implementada | `ServicioController` |
| 16 | Reactivar servicio dado de baja | catalog | Implementada | `POST /api/catalog/services/{id}/activate` |
| 17 | CRUD de repuestos | catalog | Implementada | `RepuestoController` |
| 18 | Repuestos que usa cada servicio | catalog | Implementada | `GET/PUT /api/catalog/services/{id}/parts` |
| 19 | Consulta de repuestos bajo stock mínimo | catalog | Implementada | `GET /api/catalog/parts/low-stock` |
| 20 | Aislamiento por empresa | catalog | Implementada | `AislamientoPorEmpresaTest` |
| 21 | Descuento de stock al asignar una orden (consumidor) | catalog | Implementada | `mensajeria/ordenes/OrdenAsignadaConsumer` (catalog #110) |
| 22 | Alerta de stock bajo mínimo (exchange direct) | catalog | Implementada | `StockAlertaPublisher`, `catalogo.stock.exchange` |

## 4. Órdenes de trabajo (ms-digitalfix-workorders)

| # | Funcionalidad | Componente | Estado | Evidencia |
|---|---|---|---|---|
| 23 | Crear orden | workorders | Implementada | `POST /api/workorders` |
| 24 | Ciclo de vida con transiciones validadas (409 si no corresponde) | workorders | Implementada | CREADA → ASIGNADA → EN_DESPLAZAMIENTO → EN_EJECUCION → CERRADA / CANCELADA, `TransicionInvalida` |
| 25 | Asignar y reasignar técnico | workorders | Implementada | `PUT /api/workorders/{id}/asignacion` |
| 26 | Fichas de técnicos (alta, edición, baja) | workorders | Implementada | `TecnicoController` |
| 27 | Vinculación automática del técnico con su cuenta (oid, correo o alta con datos del token) | workorders | Implementada | `TecnicoService.delUsuario`, `RolTecnicoTest` (workorders #80) |
| 28 | Bandeja del técnico | workorders | Implementada | `GET /api/workorders/mias` |
| 29 | Comentario opcional en cada cambio de estado y asignación | workorders | Implementada | `CambioEstadoDto.comentario`, `HistorialYDetalleTest` (workorders #80) |
| 30 | Historial de estados y detalle de la orden | workorders | Implementada | `V7__historial_de_estados.sql`, `GET /api/workorders/{id}` (workorders #80) |
| 31 | Visibilidad por rol (cliente: las suyas; técnico: las asignadas) | workorders | Implementada | `OrdenDeTrabajoService.detalle/listar`, `HistorialYDetalleTest` (workorders #80) |
| 32 | Filtros por estado y rango de fechas en el backend | workorders | Implementada | `GET /api/workorders?status=&from=&to=` (workorders #80) |
| 33 | Eventos de orden publicados con comentario | workorders | Implementada | `OrdenEventoPublisher`, `ordenes.eventos.<tipo>` |

## 5. Mensajería RabbitMQ

| # | Funcionalidad | Componente | Estado | Evidencia |
|---|---|---|---|---|
| 34 | Exchange topic de negocio de órdenes | workorders + consumidores | Implementada | `ordenes.negocio.exchange` |
| 35 | Exchange direct de stock | catalog + notify | Implementada | `catalogo.stock.exchange`, `stock.bajo-minimo` |
| 36 | Exchange topic de usuarios | usuarios + audit | Implementada | `usuarios.negocio.exchange`, `usuarios.eventos.#` (audit #42) |
| 37 | Una cola por caso de uso, cada una con su DLQ | todos | Implementada | `ordenes.auditoria`, `ordenes.reportes`, `ordenes.avisos`, `catalogo.stock.ordenes`, `notify.stock`, `usuarios.auditoria` |
| 38 | Beans de Queue, Exchange y Binding por caso de uso, separados de la lógica | todos | Implementada | `config/RabbitMQConfig` en cada servicio |
| 39 | Nombres centralizados en configuración | todos | Implementada | `application.yml` `amqp.*` |
| 40 | Consumidores `@RabbitListener` agrupados por dominio | audit, report, notify, catalog | Implementada | paquetes `mensajeria.ordenes`, `mensajeria.stock`, `mensajeria.usuarios` |
| 41 | ACK manual y manejo de errores diferenciado | audit, report, notify, catalog | Implementada | `ProcesadorDeMensajes`: inválido a DLQ sin reintento; transitorio con 3 reintentos y espera creciente, luego DLQ; otro error a DLQ. `ProcesadorDeMensajesTest` en cada servicio |
| 42 | Idempotencia ante entregas repetidas | audit, notify | Implementada | `eventKey` única en audit, `TicketDespachoService` |
| 43 | Cluster de 2 nodos RabbitMQ | infra | Implementada | `docker-compose.yml` (`rabbitmq1`, `rabbitmq2`), `compose/rabbitmq/rabbitmq.conf` |

## 6. Administrador de RabbitMQ (ms-digitalfix-rabbitadmin)

| # | Funcionalidad | Componente | Estado | Evidencia |
|---|---|---|---|---|
| 44 | Crear y eliminar colas (con DLQ opcional) | rabbitadmin | Implementada | `POST /queues` (`conDlq`), `DELETE /queues/{nombre}` |
| 45 | Crear y eliminar exchanges | rabbitadmin | Implementada | `POST /exchanges`, `DELETE /exchanges/{nombre}` |
| 46 | Crear y eliminar bindings | rabbitadmin | Implementada | `POST /bindings`, `DELETE /bindings?cola=&exchange=&routingKey=` |
| 47 | Listar colas con mensajes, consumidores y DLQ | rabbitadmin | Implementada | `GET /queues` (rabbitadmin #2) |
| 48 | Listar exchanges del sistema | rabbitadmin | Implementada | `GET /exchanges` (rabbitadmin #2) |
| 49 | Ver mensajes de una DLQ sin consumirlos | rabbitadmin | Implementada | `GET /queues/{nombre}/messages` (rabbitadmin #2) |
| 50 | Reprocesar una DLQ hacia su cola de origen | rabbitadmin | Implementada | `POST /queues/{dlq}/reprocess` (rabbitadmin #2) |
| 51 | Vaciar una cola | rabbitadmin | Implementada | `DELETE /queues/{nombre}/messages` (rabbitadmin #2) |
| 52 | Validación de entrada (DTOs y nombres) | rabbitadmin | Implementada | `jakarta.validation` en los DTOs, `validarNombre` |
| 53 | `RabbitAdminService` como única puerta a `RabbitAdmin` | rabbitadmin | Implementada | `RabbitAdminService`, `ColaMuertaService` |

## 7. Notificaciones (ms-digitalfix-notify)

| # | Funcionalidad | Componente | Estado | Evidencia |
|---|---|---|---|---|
| 54 | Aviso de cambio de estado al cliente (con comentario del técnico) | notify | Implementada | `GET /api/avisos`, `AvisoService` (notify #48) |
| 55 | Aviso de stock bajo mínimo | notify | Implementada | `GET /api/avisos/stock` |
| 56 | Ticket de despacho al asignar una orden | notify | Implementada | `TicketDespachoService`, `GET /api/avisos/despachos` |
| 57 | Envío real por correo (SMTP) | notify | Pendiente | hoy el envío queda registrado en el log |
| 58 | Informe técnico en PDF | notify | Pendiente | se puede generar en `TicketDespachoService.enviar()` |

## 8. Reportes (ms-digitalfix-report)

| # | Funcionalidad | Componente | Estado | Evidencia |
|---|---|---|---|---|
| 59 | Proyección de eventos de órdenes por empresa | report | Implementada | `ProyeccionDeOrdenes`, `V3__empresa_en_reporte.sql` (report #37) |
| 60 | Indicadores operacionales | report | Implementada | `GET /api/reports/indicators` |
| 61 | Servicios más solicitados | report | Implementada | `GET /api/reports/top-services` |
| 62 | Órdenes por hora del día | report + frontend | Implementada | `GET /api/reports/orders-by-hour` (report #37, frontend #254) |
| 63 | Exportar reportes a CSV | frontend | Implementada | botón Exportar en Reportes |

## 9. Auditoría (ms-digitalfix-audit)

| # | Funcionalidad | Componente | Estado | Evidencia |
|---|---|---|---|---|
| 64 | Registro de eventos de órdenes con detalle legible | audit | Implementada | `AuditEventoConsumer`, `V5__eventos_sin_correlacion_y_detalle.sql` (audit #42) |
| 65 | Registro de eventos de usuarios | audit | Implementada | `UsuarioEventoConsumer` (audit #42) |
| 66 | Consulta paginada con filtros (tipo, orden, autor, fechas) | audit | Implementada | `GET /api/audit/events` |
| 67 | Retraso de la auditoría | audit | Implementada | `GET /api/audit/lag` |

## 10. Frontend

| # | Funcionalidad | Componente | Estado | Evidencia |
|---|---|---|---|---|
| 68 | Panel según el rol (cliente, gestión) | frontend | Implementada | `dashboard.spec` (frontend #254) |
| 69 | Detalle de orden con línea de tiempo | frontend | Implementada | `orden-detalle.spec` (frontend #254) |
| 70 | Diálogo de cambio de estado con comentario opcional | frontend | Implementada | `cambio-estado.dialog.spec` (frontend #254) |
| 71 | Pantallas de catálogo, órdenes, técnicos, reportes, auditoría y notificaciones | frontend | Implementada | `features/*` |

## 11. Infraestructura, calidad y despliegue

| # | Funcionalidad | Componente | Estado | Evidencia |
|---|---|---|---|---|
| 72 | docker-compose (Oracle, RabbitMQ y microservicios) | infra | Implementada | `docker-compose.yml`, `docker-compose-backend.yml`, `docker-compose-datos.yml` |
| 73 | Esquema por microservicio con Flyway | todos | Implementada | `db/migration` en cada servicio |
| 74 | Pruebas automatizadas | todos | Implementada | JUnit en cada microservicio, Vitest en el frontend (142 pruebas) |
| 75 | `.gitignore` y sin credenciales en los repositorios | todos | Implementada | variables de entorno en compose |
| 76 | Despliegue en la nube (EC2) | infra | Parcial | desplegado; falta reconstruir las imágenes de esta entrega |
| 77 | API Gateway con autorizador JWT delante del BFF | infra | Parcial | el BFF valida el JWT; el gateway solo enruta |

## Resumen

| Estado | Cantidad |
|---|---|
| Implementada | 73 |
| Parcial | 2 |
| Pendiente | 2 |
| **Total** | **77** |

Funcionalidades implementadas y operativas: **73 de 77 = 94,8 %**.

Lo que queda: envío real de correo y el informe técnico en PDF (notify), y
dejar cerrados el despliegue de esta entrega y el autorizador del gateway.

## Pull Requests de esta entrega

- ms-digitalfix-workorders #80: historial con comentario, detalle por rol, filtros y alta automática del técnico.
- ms-digitalfix-audit #42: auditoría sin correlación obligatoria, detalle y eventos de usuarios.
- ms-digitalfix-report #37: proyección por empresa y órdenes por hora.
- ms-digitalfix-usuarios #22: rol, nombre y correo sincronizados con el tenant.
- ms-digitalfix-bff #230: correlación, sincronización del perfil y detalle de orden.
- ms-digitalfix-notify #48: consumidores por dominio y errores diferenciados.
- ms-digitalfix-catalog #110: consumidor en `mensajeria` y errores diferenciados.
- ms-digitalfix-rabbitadmin #2: gestión de colas y colas muertas.
- digitalfix-frontend #254: detalle de orden, comentario al cambiar estado y panel por rol.

## Cómo verificar cada bloque

- **Mensajería y DLQ:** `GET http://<host>:8088/queues` muestra cada cola con su DLQ y cuántos mensajes tiene. Un mensaje con JSON inválido publicado en `ordenes.auditoria.queue` llega a `ordenes.auditoria.dlq` sin reintentos (se ve en el log de audit). `POST /queues/ordenes.auditoria.dlq/reprocess` lo devuelve a su cola.
- **Órdenes y comentarios:** cambiar el estado de una orden con un comentario y abrir `/workorders/{id}`: el paso aparece en el historial, en Auditoría (filtro por orden) y en el aviso del cliente.
- **Rol del tenant:** entrar con una cuenta que tenga el rol TECNICO en Entra y sin ficha: `APP_USER` queda con ese rol y su ficha de técnico se crea sola.
- **Por rol:** el cliente ve solo sus órdenes en el panel y el listado; el técnico solo las asignadas.
