# compose

Orquestación de contenedores para desarrollo local.

| Archivo | Qué levanta |
|---|---|
| `docker-compose.datos.yml` | Oracle XE. RabbitMQ, Kafka y Zookeeper están declarados pero comentados: se activan en la fase F3. |
| `init-oracle/01-esquemas.sql` | Crea un esquema por microservicio. Corre una sola vez, al crear la base. |

El `docker-compose.yml` de las aplicaciones (frontend y los siete servicios) es
la tarea `T-05` y todavía no existe.

## Arrancar

```powershell
Copy-Item ..\.env.example ..\.env      # una sola vez, y pon tus claves
..\scripts\levantar-datos.ps1
```

## Conectarse

| | |
|---|---|
| Host | `localhost` |
| Puerto | `1521` |
| Servicio | `XEPDB1` |
| URL JDBC | `jdbc:oracle:thin:@//localhost:1521/XEPDB1` |

Cada microservicio entra con su propio esquema: `DFX_CATALOG` usa el usuario
`DFX_CATALOG`, y así con los demás. Ninguno tiene permisos sobre el esquema de
otro — eso es deliberado, no una omisión.
