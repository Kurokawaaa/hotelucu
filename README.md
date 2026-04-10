⚙️ Installation & Setup
1. Clone Repository
git clone https://github.com/kurokawaaa/hotelucu.git
cd hotelucu

3. Install Dependencies
bundle install

4. Setup Database
rails db:create
rails db:migrate

6. Setup Environment Variables 🔐

Buat file .env di root project:

MIDTRANS_SERVER_KEY=your_server_key
MIDTRANS_CLIENT_KEY=your_client_key
MIDTRANS_IS_PRODUCTION=false

5. Install dotenv (jika belum)

Tambahkan di Gemfile:

gem 'dotenv-rails'

Lalu jalankan:

bundle install

6. Pastikan .env tidak di-push ke Git

Tambahkan ke .gitignore:

.env

7. Konfigurasi Midtrans

Contoh di initializer (misalnya config/initializers/midtrans.rb):

Midtrans.server_key = ENV["MIDTRANS_SERVER_KEY"]
Midtrans.client_key = ENV["MIDTRANS_CLIENT_KEY"]
Midtrans.is_production = ENV["MIDTRANS_IS_PRODUCTION"] == "true"

8. Jalankan Server
rails s

Buka di browser:

http://localhost:3000
🔍 Troubleshooting
❌ ENV tidak terbaca

Coba cek:

rails c
ENV["MIDTRANS_SERVER_KEY"]

Jika nil:

Pastikan .env ada
Restart server

❌ Push ke GitHub ditolak (GH013)

Pastikan:

Tidak ada API key di dalam code
Gunakan .env
Reset commit jika perlu:
git reset --soft HEAD~1

🔐 Security Notes
Jangan commit API key ke repository
Gunakan .env atau Rails credentials
Regenerate key jika sudah terlanjur bocor

👨‍💻 Author
Your Name
