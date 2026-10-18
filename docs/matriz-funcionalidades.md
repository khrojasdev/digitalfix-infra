# Matriz de funcionalidades - DigitalFix

Listado del alcance del proyecto con el estado de cada funcionalidad, el
componente responsable y una evidencia verificable (endpoint, Pull Request o
clase). El estado se evalua sobre lo que esta en la rama principal de cada
repositorio (lo que se obtiene al clonar) mas los Pull Requests en revision.

**Estados:** `Implementada` · `Parcial` · `Pendiente`

## Autenticacion e identidad

| # | Funcionalidad | Componente | Estado | Evidencia |
|---|---|---|---|---|
| 1 | Login corporativo con Entra ID (OIDC / OAuth2 + PKCE) | frontend | Implementada | MSAL en `core/auth`, flujo por redireccion |
| 2 | Validacion del JWT (firma, emisor, audiencia, vigencia) | bff | Implementada | `config/SecurityConfig`, validador de audiencia propio |
| 3 | Autorizacion por rol (matriz de rutas) | bff | Implementada | `SecurityConfig` `hasAnyRole(...)` |
| 4 | Resolucion de empresa por `oid` (APP_USER) | bff + usuarios | Implementada | `ResolutorPorJwt`, `GET /api/users/{oid}` |
| 5 | Propagacion de contexto (`X-User-Oid`, `X-Company-Id`, `X-Roles`) | bff | Implementada | `ContextoUsuarioFilter` |

## Gestion de usuarios (ms-digitalfix-usuarios)

| # | Funcionalidad | Componente | Estado | Evidencia |
|---|---|---|---|---|
| 6 | Autoaprovisionamiento de usuario | usuarios | Implementada | `POST /api/users/login` |
| 7 | Listar usuarios | usuarios | Implementada | `GET /api/users` |
| 8 | Obtener usuario por `oid` | usuarios | Implementada | `GET /api/users/{oid}` |
| 9 | Activar / desactivar usuario | usuarios | Implementada | `PUT /api/users/{oid}/status` |
| 10 | Publicar evento de usuario (creado / estado) | usuarios | Implementada | PR #21, `UsuarioEventoPublisher` |

## Catalogo (ms-digitalfix-catalog)

| # | Funcionalidad | Componente | Estado | Evidencia |
|---|---|---|---|---|
| 11 | CRUD de servicios | catalog | Implementada | `ServicioController` |
| 12 | Reactivar servicio dado de baja | catalog | Implementada | `POST /api/catalog/services/{id}/activate` |
| 13 | CRUD de repuestos | catalog | Implementada | `RepuestoController` |
| 14 | Stock y consulta de bajo minimo | catalog | Implementada | `RepuestoService.bajoMinimo()` |
| 15 | Aislamiento por empresa (404 entre empresas) | catalog | Implementada | `AislamientoPorEmpresaTest` |
| 16 | Publicar alerta de stock (exchange direct) | catalog | Implementada | PR #108, `StockAlertaPublisher` |

## Ordenes de trabajo (ms-digitalfix-workorders)

| # | Funcionalidad | Componente | Estado | Evidencia |
|---|---|---|---|---|
| 17 | Ciclo de la orden (crear, asignar, iniciar, cerrar, cancelar) | workorders | Implementada | `OrdenDeTrabajoController` |
| 18 | Publicar eventos de orden (exchange topic) | workorders | Implementada | `OrdenEventoPublisher` |

## Mensajeria asincrona (RabbitMQ)

| # | Funcionalidad | Componente | Estado | Evidencia |
|---|---|---|---|---|
| 19 | Exchange topic de negocio | workorders / audit / report / notify | Implementada | `ordenes.negocio.exchange` |
| 20 | Exchange direct de stock | catalog / notify | Implementada | PR #108, `catalogo.stock.exchange` |
| 21 | Cola de auditoria + DLQ (consumidor) | audit | Implementada | `AuditEventoConsumer` |
| 22 | Cola de reportes + DLQ (consumidor) | report | Implementada | `OrdenEventoConsumer` |
| 23 | Cola de avisos de estado + DLQ (consumidor) | notify | Implementada | PR #43, `AvisoEventoConsumer` |
| 24 | Cola de avisos de stock + DLQ (consumidor) | notify | Implementada | PR #44, `StockAlertaConsumer` |
| 25 | Confirmacion manual (ACK) y manejo de error (NACK -> DLQ) | audit / report / notify | Implementada | consumidores con `basicAck` / `basicNack` |
| 26 | Nomenclatura centralizada (colas, exchanges, bindings) | todos | Implementada | `application.yml` `amqp.*` |
| 27 | Microservicio administrador (POST/DELETE colas, exchanges, bindings) | rabbitadmin | Implementada | `RabbitAdminService`, `/queues` `/exchanges` `/bindings` |
| 28 | Validacion de entrada del administrador (DTOs) | rabbitadmin | Implementada | `ColaRequest`, `ExchangeRequest` con `jakarta.validation` |
| 29 | Cluster de 2 nodos RabbitMQ | infra | Pendiente | `docker-compose` con 1 nodo; falta 2do nodo + clustering |

## Notificaciones (ms-digitalfix-notify)

| # | Funcionalidad | Componente | Estado | Evidencia |
|---|---|---|---|---|
| 30 | Aviso de cambio de estado de orden | notify | Implementada | PR #43, `GET /api/avisos` |
| 31 | Aviso de stock bajo minimo | notify | Implementada | PR #44, `GET /api/avisos/stock` |
| 32 | Ticket de despacho en PDF | notify | Pendiente | depende de routing por tipo de evento en workorders |
| 33 | Informe tecnico en PDF | notify | Pendiente | idem |
| 34 | Envio de notificaciones por correo | notify | Pendiente | plantilla Thymeleaf + SMTP |

## Reportes y auditoria

| # | Funcionalidad | Componente | Estado | Evidencia |
|---|---|---|---|---|
| 35 | Indicadores operacionales | report | Implementada | `ReporteController` |
| 36 | Registro de auditoria de eventos | audit | Implementada | `AuditService` |

## Infraestructura y despliegue

| # | Funcionalidad | Componente | Estado | Evidencia |
|---|---|---|---|---|
| 37 | docker-compose (Oracle + RabbitMQ + microservicios) | infra | Implementada | `docker-compose.yml` |
| 38 | Esquema por microservicio con Flyway | todos los MS | Implementada | `db/migration` por servicio |
| 39 | Despliegue en la nube (EC2) | infra | Parcial | desplegado; confirmar integracion completa en la demo |
| 40 | API Manager / Gateway con autorizador JWT | infra | Parcial | enrutamiento operativo; confirmar gateway vs nginx |

## Resumen

| Estado | Cantidad |
|---|---|
| Implementada | 33 |
| Parcial | 2 |
| Pendiente | 5 |
| **Total del alcance** | **40** |

Funcionalidades implementadas y operativas: **33 de 40 = 82,5%**. Las parciales
y pendientes se concentran en el ticket/informe en PDF, el correo, el segundo
nodo de RabbitMQ y la confirmacion del gateway/despliegue en la demo.
