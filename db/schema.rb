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

ActiveRecord::Schema[8.0].define(version: 2025_10_17_174436) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "close_prices", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "ticker", null: false
    t.string "date", null: false
    t.float "close", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ticker"], name: "index_close_prices_on_ticker", unique: true
  end

  create_table "portfolios", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", default: "New Portfolio"
    t.jsonb "tickers", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "weights", default: {}
  end
end
