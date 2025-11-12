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

ActiveRecord::Schema[8.1].define(version: 2025_11_11_174506) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "allocations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "enabled", default: true, null: false
    t.string "name", null: false
    t.decimal "percentage", precision: 5, scale: 2, null: false
    t.uuid "portfolio_id", null: false
    t.datetime "updated_at", null: false
    t.index ["portfolio_id", "name"], name: "index_allocations_on_portfolio_id_and_name", unique: true
    t.index ["portfolio_id"], name: "index_allocations_on_portfolio_id"
    t.check_constraint "percentage > 0::numeric AND percentage <= 100::numeric", name: "allocations_percentage_range"
  end

  create_table "cap_and_redistribute_options", force: :cascade do |t|
    t.boolean "active", default: false, null: false
    t.decimal "cap_percentage", precision: 4, scale: 3, null: false
    t.datetime "created_at", null: false
    t.uuid "portfolio_id", null: false
    t.integer "top_n", null: false
    t.datetime "updated_at", null: false
    t.jsonb "weights", default: {}, null: false
    t.index ["portfolio_id"], name: "index_cap_and_redistribute_options_on_portfolio_id"
    t.index ["weights"], name: "index_cap_and_redistribute_options_on_weights_gin", using: :gin
    t.check_constraint "cap_percentage > 0::numeric AND cap_percentage <= 1::numeric", name: "cap_percentage_range"
    t.check_constraint "top_n > 0", name: "top_n_positive"
  end

  create_table "close_prices", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.float "close"
    t.string "date"
    t.string "ticker"
    t.index ["ticker"], name: "index_close_prices_on_ticker"
  end

  create_table "portfolios", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "copy_of_id"
    t.datetime "created_at", null: false
    t.string "name"
    t.jsonb "tickers"
    t.datetime "updated_at", null: false
    t.jsonb "weights"
    t.index ["copy_of_id"], name: "index_portfolios_on_copy_of_id"
  end

  create_table "sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.uuid "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "allocations", "portfolios"
  add_foreign_key "cap_and_redistribute_options", "portfolios"
  add_foreign_key "portfolios", "portfolios", column: "copy_of_id"
  add_foreign_key "sessions", "users"
end
