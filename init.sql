CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TYPE user_role AS ENUM ('egresado', 'empresa');
CREATE TYPE request_status AS ENUM ('pendiente', 'aceptada', 'rechazada');
CREATE TYPE slot_status AS ENUM ('disponible', 'reservado', 'completado', 'cancelado');
CREATE TYPE appointment_status AS ENUM ('programada', 'completada', 'cancelada');

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255),
    role user_role NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    nombre VARCHAR(255) NOT NULL,
    experiencia_meses INTEGER DEFAULT 0 CHECK (experiencia_meses >= 0),
    rating DECIMAL(3,2) DEFAULT 0.0 CHECK (rating >= 0 AND rating <= 5),
    resenas_count INTEGER DEFAULT 0 CHECK (resenas_count >= 0),
    github_username VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE skills (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE profile_skills (
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    skill_id UUID NOT NULL REFERENCES skills(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (profile_id, skill_id)
);

CREATE TABLE requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    empresa_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    estado request_status DEFAULT 'pendiente',
    descripcion TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE slots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    fecha_inicio TIMESTAMPTZ NOT NULL,
    fecha_fin TIMESTAMPTZ,
    estado slot_status DEFAULT 'disponible',
    precio DECIMAL(10,2) NOT NULL CHECK (precio >= 0),
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE appointments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    slot_id UUID NOT NULL UNIQUE REFERENCES slots(id) ON DELETE CASCADE,
    empresa_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    estado appointment_status DEFAULT 'programada',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    appointment_id UUID UNIQUE REFERENCES appointments(id) ON DELETE SET NULL,
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    empresa_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    estrellas INTEGER NOT NULL CHECK (estrellas >= 1 AND estrellas <= 5),
    comentario TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_profiles_user_id ON profiles(user_id);
CREATE INDEX idx_requests_empresa_id ON requests(empresa_id);
CREATE INDEX idx_requests_profile_id ON requests(profile_id);
CREATE INDEX idx_slots_profile_id ON slots(profile_id);
CREATE INDEX idx_slots_fecha_inicio ON slots(fecha_inicio);
CREATE INDEX idx_appointments_empresa_id ON appointments(empresa_id);
CREATE INDEX idx_reviews_profile_id ON reviews(profile_id);
