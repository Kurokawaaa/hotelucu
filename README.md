⚙️ Getting Started
1. Clone Repository
git clone https://github.com/username/hotelucu.git
cd hotelucu
2. Install Dependencies
bundle install
3. Setup Database
rails db:create
rails db:migrate
4. Environment Configuration 🔐

Buat file .env di root project:

MIDTRANS_SERVER_KEY=your_server_key
MIDTRANS_CLIENT_KEY=your_client_key
MIDTRANS_IS_PRODUCTION=false
5. Install dotenv (jika belum ada)

Tambahkan ke Gemfile:

gem 'dotenv-rails'

Lalu jalankan:

bundle install
6. Configure Midtrans

Buat file initializer:
config/initializers/midtrans.rb

Midtrans.server_key = ENV["MIDTRANS_SERVER_KEY"]
Midtrans.client_key = ENV["MIDTRANS_CLIENT_KEY"]
Midtrans.is_production = ENV["MIDTRANS_IS_PRODUCTION"] == "true"
7. Run the Application
rails s

Akses di browser:
http://localhost:3000
