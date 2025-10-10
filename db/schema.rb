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

ActiveRecord::Schema[8.0].define(version: 2025_10_10_030050) do
  create_table "measurements", force: :cascade do |t|
    t.float "turbidity"
    t.float "predicted_bod"
    t.float "predicted_cod"
    t.float "actual_bod"
    t.float "actual_cod"
    t.string "prediction_model_version"
    t.integer "status", default: 0
    t.datetime "predicted_at"
    t.datetime "submitted_at"
    t.integer "submitter_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["submitter_id"], name: "index_measurements_on_submitter_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.integer "reviewer_id", null: false
    t.integer "reviewee_id", null: false
    t.text "comment"
    t.float "rating"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reviewee_id"], name: "index_reviews_on_reviewee_id"
    t.index ["reviewer_id"], name: "index_reviews_on_reviewer_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "store_operators", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "store_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id"], name: "index_store_operators_on_store_id"
    t.index ["user_id", "store_id"], name: "index_store_operators_on_user_id_and_store_id", unique: true
    t.index ["user_id"], name: "index_store_operators_on_user_id"
  end

  create_table "stores", force: :cascade do |t|
    t.string "name", null: false
    t.float "lat"
    t.float "lon"
    t.text "open_time"
    t.string "address", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_eco", default: false, null: false
    t.boolean "is_share", default: false, null: false
    t.index ["name", "address"], name: "index_stores_on_name_and_address", unique: true
  end

  create_table "udon_shares", force: :cascade do |t|
    t.integer "store_id", null: false
    t.string "item_name"
    t.text "description"
    t.datetime "take_down_time"
    t.string "photo_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["store_id"], name: "index_udon_shares_on_store_id"
  end

  create_table "user_settings", force: :cascade do |t|
    t.integer "user_id", null: false
    t.text "settings", default: "{}", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_settings_on_user_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_company", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "measurements", "users", column: "submitter_id"
  add_foreign_key "reviews", "stores", column: "reviewee_id"
  add_foreign_key "reviews", "users", column: "reviewer_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "store_operators", "stores"
  add_foreign_key "store_operators", "users"
  add_foreign_key "udon_shares", "stores"
  add_foreign_key "user_settings", "users"
end
