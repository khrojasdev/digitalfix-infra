# digitalfix-infra

**Proyecto:** DigitalFix — Gestión de órdenes de trabajo para una red de 20 empresas de mantención eléctrica
**Componente:** Infraestructura
**Asignatura:** DSY1107 Desarrollo Cloud Native I — Duoc UC
**Primera entrega (EP1):** 14 de septiembre de 2026

## Descripción

Orquestación local y documentación de arquitectura del sistema: los archivos de
Docker Compose, los datos semilla, los diagramas y la evidencia del despliegue.
Acá no vive código de aplicación — vive lo que hace falta para que el código de
los otros ocho repositorios se pueda levantar y probar.

## Tecnologías

Docker, Docker Compose, Oracle XE, RabbitMQ, Kafka, Zookeeper, AWS EC2, AWS API Gateway

## Integrantes

| Integrante | GitHub |
|---|---|
| Kevin Rojas | @khrojasdev |
| Christopher Perez | @ChrisPerezV |
| Diego Lopez | @DiegoLopez-f |

## Estructura

```
compose/     docker-compose y scripts de inicializacion de la base
  init-oracle/   SQL que corre al crear la base: un esquema por microservicio
seed/        datos semilla para desarrollo (T-06, pendiente)
docs/        arquitectura, modelo de datos y diagramas
scripts/     utilidades de arranque
```

## Arranque rápido

```powershell
Copy-Item .env.example .env     # una sola vez, y pon tus claves
.\scripts\levantar-datos.ps1
```

Deja Oracle XE escuchando en `localhost:1521/XEPDB1` con cinco esquemas creados,
uno por microservicio.

## Documentación

| Documento | Qué contiene |
|---|---|
| [`docs/arquitectura.md`](docs/arquitectura.md) | Componentes, flujo de una petición y despliegue |
| [`docs/modelo-datos.md`](docs/modelo-datos.md) | Modelo de datos completo, tabla por tabla |
| [`docs/diagrama-modelo-datos.md`](docs/diagrama-modelo-datos.md) | Los mismos esquemas como diagramas ER |

## Repositorios del proyecto

- [`digitalfix-frontend`](https://github.com/khrojasdev/digitalfix-frontend) — Angular 17 + MSAL
- [`ms-digitalfix-bff`](https://github.com/khrojasdev/ms-digitalfix-bff) — BFF
- [`ms-digitalfix-usuarios`](https://github.com/khrojasdev/ms-digitalfix-usuarios) — usuarios y empresas
- [`ms-digitalfix-catalog`](https://github.com/khrojasdev/ms-digitalfix-catalog) — servicios y repuestos
- [`ms-digitalfix-workorders`](https://github.com/khrojasdev/ms-digitalfix-workorders) — órdenes de trabajo
- [`ms-digitalfix-notify`](https://github.com/khrojasdev/ms-digitalfix-notify) — notificaciones
- [`ms-digitalfix-report`](https://github.com/khrojasdev/ms-digitalfix-report) — reportería
- [`ms-digitalfix-audit`](https://github.com/khrojasdev/ms-digitalfix-audit) — auditoría
- `digitalfix-infra` — **este**

## Configuración

Ninguna credencial vive en este repositorio. Todo llega por variables de entorno;
`.env.example` lista cuáles, y el `.env` real está en el `.gitignore`.
