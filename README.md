# GoWo — Infraestructura

> Capa de datos e infraestructura del proyecto GoWo. Define y gestiona la base de datos PostgreSQL mediante Docker Compose y el script de inicialización SQL con el schema completo.

---

## Índice

- [Stack tecnológico](#stack-tecnológico)
- [Arquitectura de datos](#arquitectura-de-datos)
- [Instalación y ejecución](#instalación-y-ejecución)
- [Variables de entorno](#variables-de-entorno)
- [Schema de la base de datos](#schema-de-la-base-de-datos)
- [Índices y optimización](#índices-y-optimización)
- [Comandos útiles](#comandos-útiles)
- [Decisiones técnicas](#decisiones-técnicas)

---

## Stack tecnológico

| Tecnología | Versión | Rol |
|---|---|---|
| Docker | 24+ | Contenedores |
| Docker Compose | v2 | Orquestación local |
| PostgreSQL | 15 alpine | Motor de base de datos |
| uuid-ossp | — | Extensión para UUIDs |

---

## Arquitectura de datos

El schema implementa un sistema de conexión profesional entre egresados y empresas:

```
users (egresado / empresa)
  └── profiles (1:1 con user)
        ├── profile_skills (N:M con skills)
        ├── requests (solicitudes de empresas → egresados)
        ├── slots (disponibilidad del egresado)
        │     └── appointments (citas confirmadas)
        │           └── reviews (reseñas post-cita)
        └── reviews
```

---

## Instalación y ejecución

**Prerequisito:** Docker y Docker Compose instalados.

```bash
# 1. Clonar el repo y entrar
cd gowo_infra

# 2. Configurar variables de entorno
cp .env.example .env
# Edita .env con tus credenciales

# 3. Levantar la base de datos
docker compose up -d

# 4. Verificar que está healthy
docker ps | grep gowo_postgres
```

PostgreSQL queda disponible en `localhost:5433`.

### Reinicio limpio (borra todos los datos)
```bash
docker compose down -v
docker compose up -d
```

---

## Variables de entorno

Crea `.env` en la raíz del repo (`.gitignore` ya lo excluye):

```env
POSTGRES_USER=gowo_admin
POSTGRES_PASSWORD=password_seguro
POSTGRES_DB=gowo_db
```

Estas credenciales deben coincidir con el `DATABASE_URL` del backend:
```
postgresql://gowo_admin:password_seguro@localhost:5433/gowo_db?schema=public
```

---

## Schema de la base de datos

El diagrama completo está en [`docs/schema.dbml`](./docs/schema.dbml).

### Tabla `users`
| Columna | Tipo | Descripción |
|---|---|---|
| `id` | UUID PK | Identificador único |
| `email` | VARCHAR(255) UNIQUE | Email del usuario |
| `password_hash` | VARCHAR(255) | Hash bcrypt de la contraseña |
| `role` | ENUM | `egresado` o `empresa` |
| `created_at` | TIMESTAMPTZ | Fecha de registro |

### Tabla `profiles`
| Columna | Tipo | Descripción |
|---|---|---|
| `id` | UUID PK | Identificador único |
| `user_id` | UUID FK → users | Relación 1:1 con usuario |
| `nombre` | VARCHAR(255) | Nombre completo |
| `experiencia_meses` | INTEGER | Meses de experiencia (≥ 0) |
| `rating` | DECIMAL(3,2) | Calificación promedio (0.0 – 5.0) |
| `resenas_count` | INTEGER | Contador de reseñas |
| `github_username` | VARCHAR(255) | Usuario de GitHub (opcional) |

### Tabla `requests` (lógica de negocio central)
| Columna | Tipo | Descripción |
|---|---|---|
| `id` | UUID PK | Identificador único |
| `empresa_id` | UUID FK → users | Empresa que envía la solicitud |
| `profile_id` | UUID FK → profiles | Egresado que la recibe |
| `estado` | ENUM | `pendiente` → `aceptada` / `rechazada` |
| `descripcion` | TEXT | Mensaje de la empresa |

### ENUMs definidos
```sql
user_role:         egresado | empresa
request_status:    pendiente | aceptada | rechazada
slot_status:       disponible | reservado | completado | cancelado
appointment_status: programada | completada | cancelada
```

---

## Índices y optimización

El `init.sql` crea índices sobre las columnas de búsqueda frecuente:

```sql
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_profiles_user_id ON profiles(user_id);
CREATE INDEX idx_requests_empresa_id ON requests(empresa_id);
CREATE INDEX idx_requests_profile_id ON requests(profile_id);
CREATE INDEX idx_slots_profile_id ON slots(profile_id);
CREATE INDEX idx_slots_fecha_inicio ON slots(fecha_inicio);
CREATE INDEX idx_appointments_empresa_id ON appointments(empresa_id);
CREATE INDEX idx_reviews_profile_id ON reviews(profile_id);
```

---

## Comandos útiles

```bash
# Ver logs del contenedor
docker logs -f gowo_postgres

# Conectarse a psql dentro del contenedor
docker exec -it gowo_postgres psql -U gowo_admin -d gowo_db

# Listar tablas
\dt

# Ver estructura de una tabla
\d profiles

# Consultar datos
SELECT * FROM users;
SELECT * FROM requests WHERE estado = 'pendiente';

# Salir
\q
```

### Desde el backend (Prisma)
```bash
# Sincronizar schema al DB (tras cambios en schema.prisma)
npx prisma db push

# Regenerar el cliente Prisma
npx prisma generate

# Explorador visual de la BD
npx prisma studio
```

---

## Decisiones técnicas

- **PostgreSQL sobre MySQL:** Soporte nativo de UUIDs, tipos ENUM, `TIMESTAMPTZ` y extensiones como `uuid-ossp`. Mejor para proyectos que puedan escalar con consultas complejas.
- **Puerto 5433 en el host:** Evita conflictos con instancias locales de PostgreSQL que típicamente usan el 5432.
- **`init.sql` en `docker-entrypoint-initdb.d`:** El script se ejecuta automáticamente solo en el primer arranque del contenedor (cuando el volumen está vacío), garantizando idempotencia.
- **Volumen con nombre (`gowo_pgdata`):** Persiste los datos entre reinicios de contenedor. Para limpiar completamente: `docker compose down -v`.
- **healthcheck en Compose:** Garantiza que el contenedor de PostgreSQL reporta `healthy` antes de que el backend intente conectarse, evitando errores de conexión en el arranque.
- **Constraints en el schema:** `CHECK (experiencia_meses >= 0)`, `CHECK (rating >= 0 AND rating <= 5)`, `CHECK (estrellas >= 1 AND estrellas <= 5)` garantizan integridad de datos a nivel de BD, independientemente del backend.
