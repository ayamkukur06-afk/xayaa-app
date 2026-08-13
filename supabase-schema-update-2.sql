-- =========================================================
-- XAYA — supabase-schema-update-2.sql
-- MIGRASI TAMBAHAN #2 untuk fitur baru:
--   1) Model AI dinamis (admin bisa tambah/nonaktifkan lewat
--      Panel Admin, langsung kelihatan semua pengguna)
--   2) Chat Global (satu ruang obrolan bersama untuk SEMUA
--      pengguna sekaligus)
--   3) Pengumuman Admin (admin ketik teks di Panel Admin,
--      langsung muncul di layar semua pengguna yang online)
--   4) Laporan Bug / Kesalahan Teknis (pengguna lapor lewat
--      ikon, masuk ke Panel Admin)
--
-- File ini terpisah dari supabase-schema-update.sql (migrasi
-- sebelumnya) supaya kamu tidak perlu menjalankan ulang yang
-- lama. Aman dijalankan berkali-kali (idempotent).
--
-- Jalankan SATU KALI di:
-- Dashboard Supabase > project kamu > SQL Editor > New query
-- =========================================================

-- ---------- 1. Model AI dinamis ----------
-- Ditambahkan admin lewat Panel Admin (nama model + API key Groq),
-- lalu otomatis muncul di pilihan model semua pengguna.
-- "Hapus Permanen" di UI = baris ini betulan dihapus dari tabel.
-- "Hapus Sementara" di UI = kolom disabled_until diisi tanggal/jam
--   tertentu; model disembunyikan dari pengguna sampai waktu itu
--   lewat, lalu otomatis muncul lagi tanpa perlu aksi admin lagi.
create table if not exists xaya_ayam_models (
  id                     bigint generated always as identity primary key,
  name                   text not null unique,
  model_id               text not null,
  api_key                text not null,
  created_by             text not null,
  created_at             timestamptz not null default now(),
  disabled_until         timestamptz
);

alter table xaya_ayam_models enable row level security;

-- CATATAN JUJUR: seperti tabel lain di XAYA, kebijakan publik ini
-- artinya API key model yang kamu tambahkan bisa dibaca siapa pun
-- yang punya SUPABASE_ANON_KEY (yaitu semua pengunjung situs) lewat
-- DevTools — bukan cuma lewat tombol di UI. Jangan masukkan API key
-- yang dipakai untuk hal lain yang sensitif.
drop policy if exists "public read models" on xaya_ayam_models;
create policy "public read models" on xaya_ayam_models for select using (true);
drop policy if exists "public insert models" on xaya_ayam_models;
create policy "public insert models" on xaya_ayam_models for insert with check (true);
drop policy if exists "public update models" on xaya_ayam_models;
create policy "public update models" on xaya_ayam_models for update using (true);
drop policy if exists "public delete models" on xaya_ayam_models;
create policy "public delete models" on xaya_ayam_models for delete using (true);

alter publication supabase_realtime add table xaya_ayam_models;

-- ---------- 2. Chat Global (semua pengguna, satu ruang bersama) ----------
create table if not exists xaya_ayam_global_messages (
  id          bigint generated always as identity primary key,
  from_user   text not null,
  content     text,
  file_url    text,
  file_type   text, -- 'image' | 'video' | 'file'
  file_name   text,
  created_at  timestamptz not null default now()
);
create index if not exists xaya_ayam_global_messages_created_idx
  on xaya_ayam_global_messages (created_at);

alter table xaya_ayam_global_messages enable row level security;
drop policy if exists "public read global" on xaya_ayam_global_messages;
create policy "public read global" on xaya_ayam_global_messages for select using (true);
drop policy if exists "public insert global" on xaya_ayam_global_messages;
create policy "public insert global" on xaya_ayam_global_messages for insert with check (true);

alter publication supabase_realtime add table xaya_ayam_global_messages;

-- ---------- 3. Pengumuman Admin -> semua pengguna ----------
-- Admin ketik pesan di Panel Admin -> baris baru masuk ke sini ->
-- semua pengguna yang sedang online langsung lihat sebagai banner,
-- lewat Supabase Realtime (tidak perlu refresh halaman).
create table if not exists xaya_ayam_broadcasts (
  id          bigint generated always as identity primary key,
  message     text not null,
  created_by  text not null,
  created_at  timestamptz not null default now()
);

alter table xaya_ayam_broadcasts enable row level security;
drop policy if exists "public read broadcasts" on xaya_ayam_broadcasts;
create policy "public read broadcasts" on xaya_ayam_broadcasts for select using (true);
drop policy if exists "public insert broadcasts" on xaya_ayam_broadcasts;
create policy "public insert broadcasts" on xaya_ayam_broadcasts for insert with check (true);

alter publication supabase_realtime add table xaya_ayam_broadcasts;

-- ---------- 4. Laporan Bug / Kesalahan Teknis ----------
-- Dikirim pengguna lewat ikon laporan, masuk ke daftar di Panel Admin.
create table if not exists xaya_ayam_reports (
  id          bigint generated always as identity primary key,
  from_user   text not null,
  message     text not null,
  created_at  timestamptz not null default now(),
  resolved    boolean not null default false
);

alter table xaya_ayam_reports enable row level security;
drop policy if exists "public read reports" on xaya_ayam_reports;
create policy "public read reports" on xaya_ayam_reports for select using (true);
drop policy if exists "public insert reports" on xaya_ayam_reports;
create policy "public insert reports" on xaya_ayam_reports for insert with check (true);
drop policy if exists "public update reports" on xaya_ayam_reports;
create policy "public update reports" on xaya_ayam_reports for update using (true);
drop policy if exists "public delete reports" on xaya_ayam_reports;
create policy "public delete reports" on xaya_ayam_reports for delete using (true);

alter publication supabase_realtime add table xaya_ayam_reports;
