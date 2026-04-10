# ADMIN
User.find_or_create_by!(email: "admin@hotel.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = "admin"
end

# USER
User.find_or_create_by!(email: "user@hotel.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = "user"
end

User.find_or_create_by!(email: "resepsionis@hotel.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = "resepsionis"
end
