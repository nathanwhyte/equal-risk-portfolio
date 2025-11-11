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

ActiveRecord::Schema[8.1].define(version: 2025_11_11_145954) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "allocations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "cap_and_redistribute_options", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "close_prices", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.float "close"
    t.string "date"
    t.string "ticker"
    t.index ["ticker"], name: "index_close_prices_on_ticker"
  end

  create_table "portfolio_versions", force: :cascade do |t|
    t.float "cap_percentage"
    t.datetime "created_at", null: false
    t.string "notes"
    t.uuid "portfolio_id", null: false
    t.jsonb "tickers", null: false
    t.string "title"
    t.integer "top_n"
    t.integer "version_number", null: false
    t.jsonb "weights", null: false
    t.index ["created_at"], name: "index_portfolio_versions_on_created_at"
    t.index ["portfolio_id", "created_at"], name: "index_portfolio_versions_on_portfolio_and_created_at"
    t.index ["portfolio_id", "version_number"], name: "index_portfolio_versions_on_portfolio_and_version", unique: true
    t.index ["portfolio_id"], name: "index_portfolio_versions_on_portfolio_id"
    t.index ["tickers"], name: "index_portfolio_versions_on_tickers_gin", using: :gin
    t.index ["weights"], name: "index_portfolio_versions_on_weights_gin", using: :gin
  end

  create_table "portfolios", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.jsonb "allocations"
    t.datetime "created_at", null: false
    t.string "name"
    t.jsonb "tickers"
    t.datetime "updated_at", null: false
    t.jsonb "weights"
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

  add_foreign_key "portfolio_versions", "portfolios"
  add_foreign_key "sessions", "users"
end
