/* =========================================================
   admin.config.js — GANTI KODE ADMIN DI SINI SAJA
   File terpisah khusus dari config.js/script.js supaya kamu
   gampang gonta-ganti kode admin tanpa bongkar file lain, dan
   supaya gampang disembunyikan dari repo publik (lihat catatan
   .gitignore di bawah).

   Nama panggilan yang PERSIS SAMA dengan nilai di bawah ini
   otomatis jadi admin/developer XAYA saat login — tidak perlu
   ketik "Kode Admin" manual lagi di Pengaturan (walau kolom itu
   masih ada dan tetap berfungsi sebagai cara alternatif).
   ========================================================= */
const XAYA_ADMIN_CODE = "ayamkukurayam";

/* ---------------------------------------------------------
   CATATAN JUJUR (baca ini sebelum ganti-ganti):
   1. XAYA tidak punya sistem login/password sungguhan (nama
      panggilan cuma disimpan di localStorage browser), jadi
      kode di atas HANYA kunci sisi-klien untuk menyembunyikan
      tombol admin dari pengguna biasa — BUKAN proteksi keamanan
      sungguhan. Siapa pun yang membuka file ini di DevTools
      browser (klik kanan > View Page Source / Sources tab) bisa
      langsung baca kodenya.
   2. Siapa pun yang punya SUPABASE_ANON_KEY di config.js (yaitu
      SEMUA pengunjung situs, karena key itu ikut terkirim ke
      browser mereka) secara teknis bisa memanggil Supabase API
      langsung lewat DevTools Console, tanpa lewat tombol admin
      sama sekali — termasuk aksi ban/kick/mute/hapus/kelola
      model AI. Untuk keamanan sungguhan dibutuhkan sistem login
      + aturan akses di sisi server, di luar cakupan aplikasi
      statis (HTML/CSS/JS murni tanpa backend) ini.
   3. Kalau kamu hosting XAYA dari repo GitHub PUBLIC, siapapun
      yang buka repo-nya juga bisa baca file ini langsung. Kalau
      mau kode admin tidak ikut ke-commit, tambahkan baris ini ke
      file .gitignore di root project:

        admin.config.js

      lalu commit ulang tanpa file ini (host file-nya manual saja
      di hosting kamu, di luar Git). Jangan lupa deploy dulu
      versi terbaru filenya secara manual tiap kali ganti kode.
   --------------------------------------------------------- */
