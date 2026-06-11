-- 1. Tambahkan data Dosen & Mahasiswa dummy ke auth.users
-- Password untuk keduanya adalah: password123
INSERT INTO auth.users (
  id, instance_id, aud, role, email, encrypted_password, 
  email_confirmed_at, raw_app_meta_data, raw_user_meta_data, 
  created_at, updated_at
)
VALUES 
  (
    'd05e0000-0000-0000-0000-000000000000', 
    '00000000-0000-0000-0000-000000000000', 
    'authenticated', 'authenticated', 'dosen@test.com', 
    crypt('password123', gen_salt('bf')), 
    now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()
  ),
  (
    'a11a0000-0000-0000-0000-000000000000', 
    '00000000-0000-0000-0000-000000000000', 
    'authenticated', 'authenticated', 'siswa@test.com', 
    crypt('password123', gen_salt('bf')), 
    now(), '{"provider":"email","providers":["email"]}', '{}', now(), now()
  )
ON CONFLICT (id) DO NOTHING;

-- 2. Tambahkan data profil Dosen & Mahasiswa dummy
INSERT INTO public.profiles (id, email, full_name, nim_or_nip, role, prodi)
VALUES 
  ('d05e0000-0000-0000-0000-000000000000', 'dosen@test.com', 'Dr. Budi Santoso', '198001012005011001', 'dosen', 'Teknik Informatika'),
  ('a11a0000-0000-0000-0000-000000000000', 'siswa@test.com', 'Siswa Dummy', '1122334455', 'mahasiswa', 'Teknik Informatika')
ON CONFLICT (id) DO NOTHING;

-- 3. Tambahkan 3 Mata Kuliah Dummy yang diajar oleh Dosen tersebut
INSERT INTO public.courses (id, code, name, lecturer_id, schedule_time, schedule_day)
VALUES 
  ('c0010000-0000-0000-0000-000000000000', 'TI101', 'Pemrograman Web', 'd05e0000-0000-0000-0000-000000000000', '08:00 - 10:30', 'Senin'),
  ('c0020000-0000-0000-0000-000000000000', 'TI102', 'Struktur Data', 'd05e0000-0000-0000-0000-000000000000', '13:00 - 15:30', 'Selasa'),
  ('c0030000-0000-0000-0000-000000000000', 'TI103', 'Kecerdasan Buatan', 'd05e0000-0000-0000-0000-000000000000', '09:00 - 11:30', 'Kamis')
ON CONFLICT (id) DO NOTHING;

-- 4. Masukkan SEMUA mahasiswa (termasuk akun Anda sendiri) ke mata kuliah dummy tersebut
INSERT INTO public.enrollments (student_id, course_id)
SELECT p.id, c.id
FROM public.profiles p
CROSS JOIN public.courses c
WHERE p.role = 'mahasiswa' AND c.id IN (
  'c0010000-0000-0000-0000-000000000000', 
  'c0020000-0000-0000-0000-000000000000', 
  'c0030000-0000-0000-0000-000000000000'
)
ON CONFLICT (student_id, course_id) DO NOTHING;

-- 5. Tambahkan 1 riwayat absensi (Hadir) untuk hari ini untuk SEMUA mahasiswa di Pemrograman Web
-- Pertama, buat Sesi Absensi
INSERT INTO public.attendance_sessions (id, course_id, lecturer_id, topic, qr_token, started_at, expires_at, is_active)
VALUES (
  '5e551000-0000-0000-0000-000000000000',
  'c0010000-0000-0000-0000-000000000000',
  'd05e0000-0000-0000-0000-000000000000',
  'Pengenalan HTML & CSS',
  'dummy_qr_token_123',
  now() - interval '2 hours',
  now() - interval '1 hours',
  false
)
ON CONFLICT (id) DO NOTHING;

-- Kedua, buat data kehadiran (Hadir)
INSERT INTO public.attendances (session_id, student_id, status, check_in_at)
SELECT '5e551000-0000-0000-0000-000000000000', p.id, 'hadir', now() - interval '1 hour 50 minutes'
FROM public.profiles p
WHERE p.role = 'mahasiswa'
ON CONFLICT (session_id, student_id) DO NOTHING;
