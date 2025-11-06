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

ActiveRecord::Schema[7.2].define(version: 2025_11_06_134114) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "cards", force: :cascade do |t|
    t.string "name", limit: 50, null: false
    t.text "memo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.bigint "group_id"
    t.index ["group_id"], name: "index_cards_on_group_id"
    t.index ["user_id"], name: "index_cards_on_user_id"
    t.check_constraint "user_id IS NOT NULL AND group_id IS NULL OR user_id IS NULL AND group_id IS NOT NULL", name: "cards_must_belong_to_user_or_group"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", limit: 20, null: false
    t.integer "display_order", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["display_order"], name: "index_categories_on_display_order", unique: true
  end

  create_table "comments", force: :cascade do |t|
    t.bigint "card_id", null: false
    t.bigint "group_membership_id", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["card_id", "created_at"], name: "index_comments_on_card_id_and_created_at"
    t.index ["card_id"], name: "index_comments_on_card_id"
    t.index ["group_membership_id"], name: "index_comments_on_group_membership_id"
  end

  create_table "group_memberships", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "group_id", null: false
    t.string "group_nickname", limit: 20
    t.string "role", default: "member", null: false
    t.string "guest_token", limit: 64
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id", "group_nickname"], name: "index_group_memberships_on_group_id_and_group_nickname", unique: true
    t.index ["group_id"], name: "index_group_memberships_on_group_id"
    t.index ["guest_token"], name: "index_group_memberships_on_guest_token"
    t.index ["user_id", "group_id"], name: "index_group_memberships_on_user_id_and_group_id", unique: true
    t.index ["user_id"], name: "index_group_memberships_on_user_id"
  end

  create_table "groups", force: :cascade do |t|
    t.integer "created_by_user_id", null: false
    t.string "name", limit: 30, null: false
    t.string "invite_token", limit: 64, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_user_id"], name: "index_groups_on_created_by_user_id"
    t.index ["invite_token"], name: "index_groups_on_invite_token", unique: true
  end

  create_table "likes", force: :cascade do |t|
    t.bigint "card_id", null: false
    t.bigint "group_membership_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["card_id", "group_membership_id"], name: "index_likes_on_card_id_and_group_membership_id", unique: true
    t.index ["card_id"], name: "index_likes_on_card_id"
    t.index ["group_membership_id"], name: "index_likes_on_group_membership_id"
  end

  create_table "schedule_spots", force: :cascade do |t|
    t.bigint "spot_id"
    t.integer "global_position", null: false
    t.integer "day_number", null: false
    t.time "start_time"
    t.time "end_time"
    t.boolean "is_custom_entry", default: false, null: false
    t.string "snapshot_name"
    t.integer "snapshot_category_id"
    t.string "snapshot_address"
    t.string "snapshot_phone_number"
    t.string "snapshot_website_url"
    t.text "memo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "schedule_id", null: false
    t.index ["schedule_id", "day_number"], name: "index_ss_on_schedule_and_day"
    t.index ["schedule_id", "global_position"], name: "index_ss_on_schedule_and_position", unique: true
    t.index ["spot_id"], name: "index_schedule_spots_on_spot_id"
  end

  create_table "schedules", force: :cascade do |t|
    t.string "schedulable_type", null: false
    t.bigint "schedulable_id", null: false
    t.string "name", null: false
    t.date "start_date"
    t.date "end_date"
    t.text "memo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["schedulable_type", "schedulable_id"], name: "index_schedules_on_polymorphic", unique: true
  end

  create_table "spots", force: :cascade do |t|
    t.bigint "card_id", null: false
    t.string "name", limit: 50, null: false
    t.text "address"
    t.string "phone_number", limit: 20
    t.text "website_url"
    t.string "google_place_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "category_id", null: false
    t.index ["card_id", "google_place_id"], name: "index_spots_on_card_id_and_google_place_id", unique: true, where: "(google_place_id IS NOT NULL)"
    t.index ["card_id"], name: "index_spots_on_card_id"
    t.index ["category_id"], name: "index_spots_on_category_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "display_name", limit: 20
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "provider", limit: 64
    t.string "uid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "cards", "groups"
  add_foreign_key "cards", "users"
  add_foreign_key "comments", "cards"
  add_foreign_key "comments", "group_memberships"
  add_foreign_key "group_memberships", "groups"
  add_foreign_key "group_memberships", "users"
  add_foreign_key "groups", "users", column: "created_by_user_id"
  add_foreign_key "likes", "cards"
  add_foreign_key "likes", "group_memberships"
  add_foreign_key "schedule_spots", "schedules"
  add_foreign_key "schedule_spots", "spots"
  add_foreign_key "spots", "cards"
  add_foreign_key "spots", "categories"
end
