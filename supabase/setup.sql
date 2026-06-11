-- SQL Script for Setting Up Supabase Database for Smart Attendance App

-- 1. Create profiles table
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  nim_or_nip TEXT,
  role TEXT NOT NULL CHECK (role IN ('mahasiswa', 'dosen', 'admin')),
  prodi TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- 2. Create courses table
CREATE TABLE public.courses (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  code TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  class_group TEXT,
  lecturer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  lecturer2_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  schedule_time TEXT,
  schedule_day TEXT,
  room TEXT,
  semester TEXT,
  credit_hours INTEGER,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- 3. Create enrollments table
CREATE TABLE public.enrollments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  student_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  course_id UUID REFERENCES public.courses(id) ON DELETE CASCADE,
  enrolled_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  UNIQUE(student_id, course_id)
);

-- 4. Create attendance_sessions table
CREATE TABLE public.attendance_sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  course_id UUID REFERENCES public.courses(id) ON DELETE CASCADE,
  lecturer_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  meeting_number INTEGER,
  topic TEXT,
  qr_token TEXT UNIQUE NOT NULL,
  qr_expires_at TIMESTAMPTZ NOT NULL,
  status TEXT DEFAULT 'open',
  date DATE,
  start_time TIMESTAMPTZ DEFAULT now() NOT NULL,
  end_time TIMESTAMPTZ,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  radius_meters INTEGER DEFAULT 100,
  is_online BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- 5. Create attendances table
CREATE TABLE public.attendances (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  session_id UUID REFERENCES public.attendance_sessions(id) ON DELETE CASCADE,
  student_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (status IN ('hadir', 'terlambat', 'izin', 'sakit', 'alpha')),
  check_in_at TIMESTAMPTZ DEFAULT now(),
  check_out_at TIMESTAMPTZ,
  check_in_lat DOUBLE PRECISION,
  check_in_lng DOUBLE PRECISION,
  notes TEXT,
  UNIQUE(session_id, student_id)
);

-- 6. Setup Row Level Security (RLS) policies

-- Enable RLS for all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendances ENABLE ROW LEVEL SECURITY;

-- Policies for profiles
CREATE POLICY "Public profiles are viewable by everyone." 
ON public.profiles FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile." 
ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile." 
ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Policies for courses
CREATE POLICY "Courses are viewable by everyone." 
ON public.courses FOR SELECT USING (true);

CREATE POLICY "Only dosen/admin can insert courses." 
ON public.courses FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role IN ('dosen', 'admin')
  )
);

CREATE POLICY "Lecturers and Admins can update their courses." 
ON public.courses FOR UPDATE USING (
  auth.uid() = lecturer_id OR auth.uid() = lecturer2_id OR 
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);

CREATE POLICY "Lecturers and Admins can delete their courses." 
ON public.courses FOR DELETE USING (
  auth.uid() = lecturer_id OR auth.uid() = lecturer2_id OR 
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Policies for enrollments
CREATE POLICY "Enrollments are viewable by everyone." 
ON public.enrollments FOR SELECT USING (true);

CREATE POLICY "Students can enroll themselves or admin." 
ON public.enrollments FOR INSERT WITH CHECK (
  auth.uid() = student_id OR
  EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);

CREATE POLICY "Students can unenroll themselves." 
ON public.enrollments FOR DELETE USING (auth.uid() = student_id);

-- Policies for attendance_sessions
CREATE POLICY "Sessions are viewable by everyone." 
ON public.attendance_sessions FOR SELECT USING (true);

CREATE POLICY "Lecturers can create sessions for their courses." 
ON public.attendance_sessions FOR INSERT WITH CHECK (auth.uid() = lecturer_id);

CREATE POLICY "Lecturers can update their sessions." 
ON public.attendance_sessions FOR UPDATE USING (auth.uid() = lecturer_id);

-- Policies for attendances
CREATE POLICY "Attendances are viewable by everyone." 
ON public.attendances FOR SELECT USING (true);

CREATE POLICY "Students can check-in themselves." 
ON public.attendances FOR INSERT WITH CHECK (auth.uid() = student_id);

CREATE POLICY "Lecturers can update attendances for their sessions." 
ON public.attendances FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM public.attendance_sessions s 
    WHERE s.id = session_id AND s.lecturer_id = auth.uid()
  )
);

-- 7. Disable RLS entirely for testing (UNCOMMENT IF RLS ISSUES OCCUR)
-- ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.courses DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.enrollments DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.attendance_sessions DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE public.attendances DISABLE ROW LEVEL SECURITY;
