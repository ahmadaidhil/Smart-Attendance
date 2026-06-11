# Smart Attendance

Sistem Presensi Mahasiswa Cerdas Berbasis Lokasi & Kode QR.

Smart Attendance adalah sebuah aplikasi berbasis Flutter (Web & Mobile) yang dirancang untuk mempermudah proses absensi mahasiswa di kampus. Aplikasi ini dilengkapi dengan panel khusus untuk Admin, Dosen, dan Mahasiswa, dengan dukungan autentikasi aman, pemindaian QR, serta validasi lokasi (GPS/Geofencing).

## Fitur Utama

- **Multi-Role Authentication**: Login khusus untuk Admin, Dosen, dan Mahasiswa.
- **QR Code Attendance**: Dosen dapat membuka sesi absensi dan menghasilkan QR Code dinamis yang bisa dipindai oleh mahasiswa.
- **Geofencing & Location Validation**: Mahasiswa hanya bisa melakukan absensi jika berada di dalam radius kampus/kelas yang ditentukan.
- **Manajemen Data Akademik**: Admin dapat mengelola profil pengguna, data mata kuliah, serta pendaftaran (enrollment) mahasiswa ke dalam kelas.
- **Rekap & Laporan Otomatis**: Dosen dan Admin dapat melihat ringkasan tingkat kehadiran secara real-time. Dosen juga dapat mengubah status absensi mahasiswa secara manual (Hadir, Izin, Sakit, Alpha).
- **Export Data**: Ekspor laporan absensi dengan mudah.
- **Backend**: Didukung sepenuhnya oleh Supabase (PostgreSQL, Authentication, Row Level Security).

## Teknologi

- **Frontend**: Flutter (Dart)
- **Backend & Database**: Supabase (PostgreSQL)
- **State Management**: Provider
- **Routing**: GoRouter
- **Layanan Lokasi & QR**: Geolocator, flutter_map, qr_flutter, mobile_scanner

## Cara Menjalankan (Local Development)

1. Lakukan *clone* repositori ini:
   ```bash
   git clone <repo-url>
   cd Smart-Attendance
   ```
2. Instal dependensi:
   ```bash
   flutter pub get
   ```
3. Atur *Database* Supabase Anda dengan menjalankan perintah SQL yang tersedia di folder `supabase/setup.sql` pada SQL Editor Supabase.
4. Sesuaikan file konfigurasi Supabase (URL dan Anon Key) di dalam kode sumber `lib/core/constants/supabase_constants.dart` atau file konfigurasi environment Anda.
5. Jalankan aplikasi:
   ```bash
   flutter run -d chrome
   ```

## Lisensi
Proyek ini dibuat untuk keperluan akademik/institusi.
