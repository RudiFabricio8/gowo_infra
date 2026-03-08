-- Enable UUID extension for generating universally unique identifiers
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- ENUMS
-- ============================================================================
CREATE TYPE user_role AS ENUM ('egresado', 'empresa');
CREATE TYPE request_status AS ENUM ('pendiente', 'aceptada', 'rechazada');
CREATE TYPE slot_status AS ENUM ('disponible', 'reservado', 'completado', 'cancelado');
CREATE TYPE appointment_status AS ENUM ('programada', 'completada', 'cancelada');

-- ============================================================================
-- TABLES
-- ============================================================================

-- USERS
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255), -- Asumimos que la autenticación requerirá guardar un hash
    role user_role NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE users IS 'Almacena la información base y rol de los usuarios del sistema (egresados y empresas).';

-- PROFILES
CREATE TABLE profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    nombre VARCHAR(255) NOT NULL,
    experiencia_meses INTEGER DEFAULT 0 CHECK (experiencia_meses >= 0),
    rating DECIMAL(3,2) DEFAULT 0.0 CHECK (rating >= 0 AND rating <= 5),
    resenas_count INTEGER DEFAULT 0 CHECK (resenas_count >= 0),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE profiles IS 'Información detallada y métricas consolidadas del egresado.';

-- SKILLS
CREATE TABLE skills (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE skills IS 'Catálogo centralizado de habilidades (ej. React, Next.js).';

-- PROFILE_SKILLS (Tabla Pivote N:M)
CREATE TABLE profile_skills (
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    skill_id UUID NOT NULL REFERENCES skills(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (profile_id, skill_id)
);
COMMENT ON TABLE profile_skills IS 'Relación N:M entre perfiles de egresados y sus habilidades tecnológicas.';

-- REQUESTS (Solicitudes)
CREATE TABLE requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    estado request_status DEFAULT 'pendiente',
    descripcion TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE requests IS 'Solicitudes de interés enviadas de una empresa a un egresado.';

-- SLOTS (Agenda)
CREATE TABLE slots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    fecha_inicio TIMESTAMPTZ NOT NULL,
    fecha_fin TIMESTAMPTZ, -- Opcional, dependiendo si los slots tienen duración variable
    estado slot_status DEFAULT 'disponible',
    precio DECIMAL(10,2) NOT NULL CHECK (precio >= 0),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE slots IS 'Bloques de tiempo disponibles (agenda) publicados por los egresados.';

-- APPOINTMENTS (Citas/Contratos)
CREATE TABLE appointments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    slot_id UUID NOT NULL UNIQUE REFERENCES slots(id) ON DELETE CASCADE,
    empresa_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    estado appointment_status DEFAULT 'programada',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE appointments IS 'Registro de la reserva formal de un slot por parte de una empresa (Cita).';

-- REVIEWS (Reseñas)
CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    appointment_id UUID UNIQUE REFERENCES appointments(id) ON DELETE SET NULL,
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    empresa_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    estrellas INTEGER NOT NULL CHECK (estrellas >= 1 AND estrellas <= 5),
    comentario TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE reviews IS 'Reseñas y calificaciones otorgadas por empresas a egresados post-cita.';

-- ============================================================================
-- INDEXES para optimizar consultas frecuentes
-- ============================================================================
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_profiles_user_id ON profiles(user_id);
CREATE INDEX idx_requests_empresa_id ON requests(empresa_id);
CREATE INDEX idx_requests_profile_id ON requests(profile_id);
CREATE INDEX idx_slots_profile_id ON slots(profile_id);
CREATE INDEX idx_slots_fecha_inicio ON slots(fecha_inicio);
CREATE INDEX idx_appointments_empresa_id ON appointments(empresa_id);
CREATE INDEX idx_reviews_profile_id ON reviews(profile_id);
