-- =========================================================
-- XAYA — supabase-schema-update.sql
-- MIGRASI TAMBAHAN untuk fitur baru: mute, hapus pengguna,
-- foto profil & bio, kirim file/gambar/video, dan grup/komunitas.
--
-- File ini AMAN dijalankan di project yang sudah pernah
-- menjalankan supabase-schema.sql sebelumnya. Kolom pakai
-- "if not exists" dan kebijakan (policy) di-drop dulu sebelum
-- dibuat ulang (Postgres tidak punya "create policy if not
-- exists"), jadi aman dijalankan berkali-kali tanpa menghapus
-- data yang sudah ada.
--
-- Jalankan SATU KALI di:
-- Dashboard Supabase > project kamu > SQL Editor > New query
-- =========================================================

-- ---------- 1. Kolom baru di tabel pengguna ----------
-- muted: dibatasi kirim pesan (DM & grup) oleh admin, tanpa di-ban penuh.
-- avatar_url: link foto profil (disimpan di Storage bucket "xaya-uploads").
-- bio: bio singkat pengguna, bisa diubah sendiri di Pengaturan.
alter table xaya_ayam_users add column if not exists muted boolean not null default false;
alter table xaya_ayam_users add column if not exists avatar_url text;
alter table xaya_ayam_users add column if not exists bio text;

drop policy if exists "public delete users" on xaya_ayam_users;
create policy "public delete users" on xaya_ayam_users
  for delete using (true);

-- ---------- 2. Kolom baru di tabel pesan pribadi (DM) ----------
-- Dipakai untuk lampiran file/gambar/video yang dikirim di chat pribadi.
-- content dibolehkan kosong karena pesan boleh berupa file saja tanpa teks.
alter table xaya_ayam_messages add column if not exists file_url text;
alter table xaya_ayam_messages add column if not exists file_type text; -- 'image' | 'video' | 'file'
alter table xaya_ayam_messages add column if not exists file_name text;
alter table xaya_ayam_messages alter column content drop not null;

-- ---------- 3. Grup / komunitas pengguna ----------
create table if not exists xaya_ayam_groups (
  id          bigint generated always as identity primary key,
  name        text not null,
  bio         text,
  avatar_url  text,
  created_by  text not null,
  created_at  timestamptz not null default now()
);

create table if not exists xaya_ayam_group_members (
  group_id    bigint not null references xaya_ayam_groups(id) on delete cascade,
  username    text not null,
  role        text not null default 'member', -- 'owner' | 'member'
  joined_at   timestamptz not null default now(),
  primary key (group_id, username)
);

create table if not exists xaya_ayam_group_messages (
  id          bigint generated always as identity primary key,
  group_id    bigint not null references xaya_ayam_groups(id) on delete cascade,
  from_user   text not null,
  content     text,
  file_url    text,
  file_type   text, -- 'image' | 'video' | 'file'
  file_name   text,
  created_at  timestamptz not null default now()
);

create index if not exists xaya_ayam_group_messages_group_idx
  on xaya_ayam_group_messages (group_id, created_at);

alter table xaya_ayam_groups enable row level security;
alter table xaya_ayam_group_members enable row level security;
alter table xaya_ayam_group_messages enable row level security;

-- CATATAN JUJUR: sama seperti tabel lain di XAYA, kebijakan di
-- bawah ini publik lewat anon key (tidak ada login sungguhan),
-- jadi ini bukan proteksi keamanan sungguhan — lihat catatan
-- di supabase-schema.sql.
drop policy if exists "public read groups" on xaya_ayam_groups;
create policy "public read groups" on xaya_ayam_groups for select using (true);
drop policy if exists "public insert groups" on xaya_ayam_groups;
create policy "public insert groups" on xaya_ayam_groups for insert with check (true);
drop policy if exists "public update groups" on xaya_ayam_groups;
create policy "public update groups" on xaya_ayam_groups for update using (true);
drop policy if exists "public delete groups" on xaya_ayam_groups;
create policy "public delete groups" on xaya_ayam_groups for delete using (true);

drop policy if exists "public read group_members" on xaya_ayam_group_members;
create policy "public read group_members" on xaya_ayam_group_members for select using (true);
drop policy if exists "public insert group_members" on xaya_ayam_group_members;
create policy "public insert group_members" on xaya_ayam_group_members for insert with check (true);
drop policy if exists "public delete group_members" on xaya_ayam_group_members;
create policy "public delete group_members" on xaya_ayam_group_members for delete using (true);

drop policy if exists "public read group_messages" on xaya_ayam_group_messages;
create policy "public read group_messages" on xaya_ayam_group_messages for select using (true);
drop policy if exists "public insert group_messages" on xaya_ayam_group_messages;
create policy "public insert group_messages" on xaya_ayam_group_messages for insert with check (true);

alter publication supabase_realtime add table xaya_ayam_groups;
alter publication supabase_realtime add table xaya_ayam_group_members;
alter publication supabase_realtime add table xaya_ayam_group_messages;

-- ---------- 4. Storage bucket untuk file/gambar/video/avatar ----------
-- Bucket publik supaya link foto/video bisa langsung ditampilkan di
-- <img>/<video> tanpa perlu signed URL.
insert into storage.buckets (id, name, public)
values ('xaya-uploads', 'xaya-uploads', true)
on conflict (id) do nothing;

drop policy if exists "public read xaya uploads" on storage.objects;
create policy "public read xaya uploads" on storage.objects
  for select using (bucket_id = 'xaya-uploads');
drop policy if exists "public insert xaya uploads" on storage.objects;
create policy "public insert xaya uploads" on storage.objects
  for insert with check (bucket_id = 'xaya-uploads');
drop policy if exists "public update xaya uploads" on storage.objects;
create policy "public update xaya uploads" on storage.objects
  for update using (bucket_id = 'xaya-uploads');
drop policy if exists "public delete xaya uploads" on storage.objects;
create policy "public delete xaya uploads" on storage.objects
  for delete using (bucket_id = 'xaya-uploads');

-- CATATAN JUJUR (batas ukuran file): bucket di atas tidak diberi
-- batas ukuran khusus lewat SQL ini — batas default project Supabase
-- kamu yang berlaku. Kalau mau batasi ukuran upload, atur lewat
-- Dashboard > Storage > xaya-uploads > Settings.
