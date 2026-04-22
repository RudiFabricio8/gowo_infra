# GoWo — Infraestructura

Capa de datos e infraestructura del proyecto GoWo. Contiene la configuración de **PostgreSQL** vía **Docker Compose** y el script de inicialización de la base de datos.

## Stack

- Docker + Docker Compose
- PostgreSQL 15 (alpine)
- Volúmenes Docker para persistencia

## Variables de entorno

Copia `.env.example` a `.env`:

```env
POSTGRES_USER=gowo_admin
POSTGRES_PASSWORD=gowo_secure_pwd_2026
POSTGRES_DB=gowo_db
```

## Levantar la base de datos

```bash
docker compose up -d
```

PostgreSQL estará disponible en el puerto **5433** del host.

## Reiniciar desde cero

```bash
docker compose down -v
docker compose up -d
```

## Esquema

El archivo `init.sql` crea automáticamente las tablas al iniciar el contenedor por primera vez:

- `users` — Autenticación y roles (egresado / empresa)
- `profiles` — Información del egresado con campo `github_username`
- `skills` + `profile_skills` — Catálogo N:M de habilidades
- `requests` — Solicitudes de contacto empresa → egresado
- `slots` — Disponibilidad de agenda del egresado
- `appointments` — Citas confirmadas
- `reviews` — Reseñas post-cita

El diagrama completo del esquema está en `docs/schema.dbml`.

## Después de levantar la infra

Desde el repositorio del backend, ejecutar:

```bash
npx prisma generate
npx prisma db push
```
