# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_11_050748) do
  create_table "bookings", force: :cascade do |t|
    t.string "booking_code"
    t.date "check_in"
    t.date "check_out"
    t.datetime "created_at", null: false
    t.integer "room_id", null: false
    t.string "status", default: "paid", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["room_id"], name: "index_bookings_on_room_id"
    t.index ["user_id"], name: "index_bookings_on_user_id"
  end

  create_table "facilities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "room_level_id"
    t.datetime "updated_at", null: false
    t.index ["room_level_id"], name: "index_facilities_on_room_level_id"
  end

  create_table "room_level_facilities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "facility_id", null: false
    t.integer "room_level_id", null: false
    t.datetime "updated_at", null: false
    t.index ["facility_id"], name: "index_room_level_facilities_on_facility_id"
    t.index ["room_level_id"], name: "index_room_level_facilities_on_room_level_id"
  end

  create_table "room_levels", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.integer "price"
    t.datetime "updated_at", null: false
  end

  create_table "rooms", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "room_level_id", null: false
    t.string "room_number"
    t.string "status", default: "available", null: false
    t.datetime "updated_at", null: false
    t.index ["room_level_id"], name: "index_rooms_on_room_level_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role"
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "bookings", "rooms"
  add_foreign_key "bookings", "users"
  add_foreign_key "facilities", "room_levels"
  add_foreign_key "room_level_facilities", "facilities"
  add_foreign_key "room_level_facilities", "room_levels"
  add_foreign_key "rooms", "room_levels"
end
