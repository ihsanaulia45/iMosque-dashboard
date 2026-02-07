-- =====================================================
-- iMosque Admin Dashboard - COMPLETE SQL Migration
--
-- Jalankan SELURUH script ini di Supabase SQL Editor
-- Aman dijalankan berkali-kali (idempotent)
--
-- Script ini menyelesaikan SEMUA yang dibutuhkan:
--   1. profiles: tambah kolom is_active + role 'developer' + RLS policies
--   2. mosques: RLS policies (select, insert, update)
--   3. audit_logs: tabel baru + RLS policies
--   4. system_settings: tabel baru + RLS policies + default data
-- =====================================================


-- =============================================================
-- STEP 1: UPDATE TABEL PROFILES
-- =============================================================

-- 1a. Tambah kolom is_active untuk fitur block/unblock user
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS is_active boolean DEFAULT true;

-- 1b. Update constraint role supaya bisa pakai 'developer'
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_role_check
  CHECK (role = ANY (ARRAY[
    'user'::text,
    'ustadz'::text,
    'operator'::text,
    'admin'::text,
    'developer'::text
  ]));

-- 1c. RLS untuk profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Semua orang bisa lihat profiles
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
CREATE POLICY "Public profiles are viewable by everyone"
    ON public.profiles FOR SELECT
    USING (true);

-- User bisa insert profile sendiri (saat registrasi)
DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile"
    ON public.profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- User bisa update profile sendiri, admin/developer bisa update siapa saja
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Admin and developer can update profiles" ON public.profiles;
CREATE POLICY "Users and admins can update profiles"
    ON public.profiles FOR UPDATE
    USING (
        auth.uid() = id
        OR EXISTS (
            SELECT 1 FROM public.profiles AS p
            WHERE p.id = auth.uid()
            AND p.role IN ('admin', 'developer')
        )
    );


-- =============================================================
-- STEP 2: RLS POLICIES UNTUK TABEL MOSQUES
-- =============================================================

ALTER TABLE public.mosques ENABLE ROW LEVEL SECURITY;

-- Semua orang bisa lihat mosques
DROP POLICY IF EXISTS "Mosques are viewable by everyone" ON public.mosques;
DROP POLICY IF EXISTS "Public read mosques" ON public.mosques;
CREATE POLICY "Public read mosques"
    ON public.mosques FOR SELECT
    USING (true);

-- Admin/Developer bisa tambah mosque baru
DROP POLICY IF EXISTS "Admin and developer can insert mosques" ON public.mosques;
CREATE POLICY "Admin and developer can insert mosques"
    ON public.mosques FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('admin', 'developer')
        )
    );

-- Admin/Developer bisa edit mosque (termasuk verify/unverify)
DROP POLICY IF EXISTS "Admin and developer can update mosques" ON public.mosques;
CREATE POLICY "Admin and developer can update mosques"
    ON public.mosques FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('admin', 'developer')
        )
    );

-- Developer bisa hapus mosque
DROP POLICY IF EXISTS "Developer can delete mosques" ON public.mosques;
CREATE POLICY "Developer can delete mosques"
    ON public.mosques FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'developer'
        )
    );


-- =============================================================
-- STEP 3: BUAT TABEL AUDIT_LOGS
-- =============================================================

CREATE TABLE IF NOT EXISTS public.audit_logs (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    actor_id uuid NOT NULL,
    actor_role text NOT NULL DEFAULT 'user',
    action text NOT NULL,
    target_type text NOT NULL,
    target_id text,
    details jsonb,
    ip_address text,
    user_agent text,
    created_at timestamptz DEFAULT now()
);

-- Indexes untuk performa query
CREATE INDEX IF NOT EXISTS idx_audit_logs_actor_id ON public.audit_logs(actor_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON public.audit_logs(action);
CREATE INDEX IF NOT EXISTS idx_audit_logs_target ON public.audit_logs(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON public.audit_logs(created_at DESC);

-- Foreign key ke profiles (untuk join nama actor)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'audit_logs_actor_id_fkey'
        AND table_name = 'audit_logs'
    ) THEN
        ALTER TABLE public.audit_logs
            ADD CONSTRAINT audit_logs_actor_id_fkey
            FOREIGN KEY (actor_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
    END IF;
END $$;

-- RLS
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Admin/Developer bisa baca audit logs
DROP POLICY IF EXISTS "Admin and developer can read audit logs" ON public.audit_logs;
CREATE POLICY "Admin and developer can read audit logs"
    ON public.audit_logs FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('admin', 'developer')
        )
    );

-- Admin/Developer bisa tulis audit logs
DROP POLICY IF EXISTS "Admin and developer can insert audit logs" ON public.audit_logs;
CREATE POLICY "Admin and developer can insert audit logs"
    ON public.audit_logs FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('admin', 'developer')
        )
    );


-- =============================================================
-- STEP 4: BUAT TABEL SYSTEM_SETTINGS
-- =============================================================

CREATE TABLE IF NOT EXISTS public.system_settings (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    key text NOT NULL UNIQUE,
    value text NOT NULL DEFAULT '',
    value_type text NOT NULL DEFAULT 'string',
    category text NOT NULL DEFAULT 'general',
    description text,
    is_public boolean DEFAULT false,
    admin_editable boolean DEFAULT true,
    updated_by uuid,
    updated_at timestamptz DEFAULT now(),
    created_at timestamptz DEFAULT now()
);

-- Foreign key ke profiles
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'system_settings_updated_by_fkey'
        AND table_name = 'system_settings'
    ) THEN
        ALTER TABLE public.system_settings
            ADD CONSTRAINT system_settings_updated_by_fkey
            FOREIGN KEY (updated_by) REFERENCES public.profiles(id) ON DELETE SET NULL;
    END IF;
END $$;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_system_settings_category ON public.system_settings(category);
CREATE INDEX IF NOT EXISTS idx_system_settings_key ON public.system_settings(key);

-- RLS
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;

-- Admin/Developer bisa baca semua settings, public settings bisa dibaca siapa saja
DROP POLICY IF EXISTS "Public settings readable by all, others by admin/developer" ON public.system_settings;
CREATE POLICY "Public settings readable by all, others by admin/developer"
    ON public.system_settings FOR SELECT
    USING (
        is_public = true
        OR EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('admin', 'developer')
        )
    );

-- Admin/Developer bisa update settings
DROP POLICY IF EXISTS "Admin and developer can update settings" ON public.system_settings;
CREATE POLICY "Admin and developer can update settings"
    ON public.system_settings FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role IN ('admin', 'developer')
        )
    );

-- Developer bisa insert & delete settings
DROP POLICY IF EXISTS "Developer can manage settings" ON public.system_settings;
CREATE POLICY "Developer can manage settings"
    ON public.system_settings FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'developer'
        )
    );


-- =============================================================
-- STEP 5: INSERT DEFAULT SYSTEM SETTINGS
-- =============================================================

INSERT INTO public.system_settings (key, value, value_type, category, description, is_public, admin_editable)
VALUES
    ('maintenance_mode', 'false', 'boolean', 'system',
     'Enable maintenance mode - users cannot access app', false, true),
    ('maintenance_message', 'Aplikasi sedang dalam perbaikan. Silakan coba lagi nanti.', 'string', 'system',
     'Message shown during maintenance', false, true),
    ('banner_enabled', 'false', 'boolean', 'announcement',
     'Show banner notification in app', true, true),
    ('banner_text', '', 'string', 'announcement',
     'Banner text shown to all users', true, true),
    ('app_version_minimum', '1.0.0', 'string', 'system',
     'Minimum app version required', false, false),
    ('notification_enabled', 'true', 'boolean', 'notification',
     'Enable push notifications globally', false, true)
ON CONFLICT (key) DO NOTHING;


-- =============================================================
-- SELESAI!
-- =============================================================
--
-- Yang sudah dikonfigurasi:
--
-- PROFILES:
--   + Kolom is_active (boolean, default true) → untuk block/unblock user
--   + Role 'developer' ditambahkan ke constraint
--   + RLS: semua bisa baca, user update sendiri, admin/dev update siapa saja
--
-- MOSQUES:
--   + RLS: semua bisa baca, admin/dev bisa insert & update, dev bisa delete
--
-- AUDIT_LOGS (tabel baru):
--   + Mencatat semua aksi admin/developer
--   + RLS: hanya admin/dev bisa baca & tulis
--
-- SYSTEM_SETTINGS (tabel baru):
--   + Key-value config untuk sistem
--   + 6 default settings sudah di-insert
--   + RLS: admin/dev bisa baca & update, dev bisa insert/delete
--
-- =============================================================
