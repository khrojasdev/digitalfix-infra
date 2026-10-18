# Matriz de pruebas - DigitalFix

Listado de las pruebas automatizadas del proyecto: qué verifica cada una, su
tipo, la evidencia (archivo) y el resultado.

## Cómo se obtuvieron los resultados

- **Frontend:** ejecutado con Vitest (`ng test`). Resultado real: **53/53 en
  verde** (20 archivos de prueba). Evidencia de la corrida al final del
  documento.
- **Backend:** cada microservicio se prueba con `./mvnw test`. Reproducir por
  servicio:

  ```bash
  cd <repo> && ./mvnw -q test
  ```

  Las pruebas de backend son unitarias y de slice (sin broker ni base externa:
  usan Mockito, `@WebMvcTest`, `@DataJpaTest` y H2), así que corren sin
  levantar RabbitMQ ni Oracle.

Leyenda de tipo: **Unit** (lógica pura con Mockito) · **Slice**
(`@WebMvcTest` / `@DataJpaTest`) · **Contexto** (`@SpringBootTest`) · **HTTP**
(HttpTestingController en Angular).

## Mensajería (lo nuevo de la EP3)

| Componente | Clase | Qué verifica | Tipo | N° |
|---|---|---|---|---|
| notify | `AvisoServiceTest` | Mapea el evento a un aviso legible, es idempotente por eventKey y tolera tipos desconocidos | Unit | 3 |
| notify | `AvisoStockServiceTest` | Traduce la alerta de stock a un aviso legible | Unit | 1 |
| catalog | `StockAlertaPublisherTest` | Publica la alerta solo cuando el repuesto queda bajo mínimo; no publica con stock suficiente | Unit | 2 |
| usuarios | `UsuarioEventoPublisherTest` | Publica un evento al crear y al cambiar el estado de un usuario | Unit | 2 |
| rabbitadmin | `RabbitAdminServiceTest` | Declara cola con DLQ, exchange direct y binding; elimina cola delegando en RabbitAdmin | Unit | 4 |
| rabbitadmin | `ColaControllerValidacionTest` | Rechaza con 400 una cola con nombre vacío; acepta una válida con 201 | Slice | 2 |

Estas seis clases cubren los indicadores de la EP3 sobre consumidores,
productores, ACK/DLQ y validación de la entrada del administrador.

## Frontend (digitalfix-frontend) — 53 pruebas, ejecutadas en verde

| Área | Archivo | Qué verifica | Tipo |
|---|---|---|---|
| Notificaciones | `features/notificaciones/notificaciones.service.spec.ts` | Pide `/api/avisos` y `/api/avisos/stock` al BFF; no manda companyId | HTTP |
| Catálogo | `features/catalog/catalogo.service.spec.ts` | Llama al BFF y nunca al microservicio; desactiva en vez de borrar | HTTP |
| Dashboard | `features/dashboard/dashboard.spec.ts` | Arma los indicadores desde llamadas reales | HTTP |
| Auth | `core/auth/guards/auth-guard.spec.ts`, `role-guard.spec.ts` | Redirige sin sesión; bloquea por rol | Unit |
| Auth | `core/auth/auth-context.service.spec.ts`, `session.service.spec.ts` | Roles desde /api/me con el token como respaldo | Unit |
| HTTP | `core/http/correlacion.interceptor.spec.ts` | Agrega X-Correlation-Id solo a la API | Unit |
| Layout y vistas | `layout.component.spec.ts`, `catalog`, `repuestos`, `reports`, `audit`, `workorders`, … | Render y navegación | Slice |

(20 archivos en total; arriba las más relevantes.)

## Backend por microservicio

| Microservicio | Clases de prueba | N° | Comando |
|---|---|---|---|
| ms-digitalfix-notify | `AvisoServiceTest`, `AvisoStockServiceTest` | 4 | `./mvnw -q test` |
| ms-digitalfix-catalog | `ServicioServiceTest`, `ServicioControllerTest`, `AislamientoPorEmpresaTest`, `RepuestoTest`, `StockAlertaPublisherTest` | 27 | `./mvnw -q test` |
| ms-digitalfix-usuarios | `AppUserServiceTest`, `AppUserControllerTest`, `UsuarioEventoPublisherTest`, `MsUsuariosApplicationTests` | 7 | `./mvnw -q test` |
| ms-digitalfix-rabbitadmin | `RabbitAdminServiceTest`, `ColaControllerValidacionTest` | 6 | `./mvnw -q test` |
| ms-digitalfix-bff | `AuthorizationMatrixTests`, `SecurityRejectionTests`, `ResolutorPorJwtTest`, `AudienceValidatorTest`, `CortacircuitosTest`, `ReintentosTest`, `SaneadorDeParametrosTest`, `ResolutorDeDesarrolloTest` | 32 | `./mvnw -q test` |
| ms-digitalfix-report | `MsDigitalfixReportApplicationTests` | 1 | `./mvnw -q test` |
| ms-digitalfix-workorders | `MsDigitalfixWorkordersApplicationTests` | 1 | `./mvnw -q test` |

## Resumen

| Capa | Pruebas | Resultado |
|---|---|---|
| Frontend (Vitest) | 53 | **Verde (ejecutado)** |
| Backend (JUnit + Mockito) | 78 | Ejecutar `./mvnw test` por repo |
| **Total** | **131** | |

## Evidencia de la corrida del frontend

```
 Test Files  20 passed (20)
      Tests  53 passed (53)
   Duration  4.26s
```
