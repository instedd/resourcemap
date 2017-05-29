# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170524230256) do

  create_table "activities", force: true do |t|
    t.integer  "user_id"
    t.integer  "collection_id"
    t.integer  "layer_id"
    t.integer  "field_id"
    t.integer  "site_id"
    t.binary   "data",          limit: 2147483647
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.string   "item_type"
    t.string   "action"
  end

  create_table "channels", force: true do |t|
    t.string   "name"
    t.boolean  "is_enable"
    t.string   "password"
    t.string   "nuntium_channel_name"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.integer  "user_id"
    t.boolean  "basic_setup"
    t.boolean  "advanced_setup"
    t.boolean  "national_setup"
  end

  create_table "collections", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.datetime "created_at",                                                              null: false
    t.datetime "updated_at",                                                              null: false
    t.decimal  "lat",                           precision: 10, scale: 6
    t.decimal  "lng",                           precision: 10, scale: 6
    t.decimal  "min_lat",                       precision: 10, scale: 6
    t.decimal  "min_lng",                       precision: 10, scale: 6
    t.decimal  "max_lat",                       precision: 10, scale: 6
    t.decimal  "max_lng",                       precision: 10, scale: 6
    t.string   "icon"
    t.integer  "quota",                                                  default: 0
    t.string   "logo"
    t.string   "anonymous_name_permission",                              default: "none"
    t.string   "anonymous_location_permission",                          default: "none"
  end

  create_table "field_histories", force: true do |t|
    t.integer  "collection_id"
    t.integer  "layer_id"
    t.string   "name"
    t.string   "code"
    t.string   "kind"
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
    t.binary   "config",        limit: 2147483647
    t.integer  "ord"
    t.datetime "valid_since"
    t.datetime "valid_to"
    t.integer  "field_id"
    t.text     "metadata"
    t.integer  "version",                          default: 0
  end

  add_index "field_histories", ["field_id"], name: "index_field_histories_on_field_id", using: :btree

  create_table "fields", force: true do |t|
    t.integer  "collection_id"
    t.integer  "layer_id"
    t.string   "name"
    t.string   "code"
    t.string   "kind"
    t.datetime "created_at",                       null: false
    t.datetime "updated_at",                       null: false
    t.binary   "config",        limit: 2147483647
    t.integer  "ord"
    t.text     "metadata"
  end

  add_index "fields", ["collection_id"], name: "index_fields_on_collection_id", using: :btree
  add_index "fields", ["layer_id"], name: "index_fields_on_layer_id", using: :btree

  create_table "gallery_images", force: true do |t|
    t.integer  "field_id"
    t.string   "guid"
    t.binary   "data",       limit: 16777215
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "gallery_images", ["field_id"], name: "index_gallery_images_on_field_id", using: :btree
  add_index "gallery_images", ["guid"], name: "index_gallery_images_on_guid", unique: true, using: :btree

  create_table "identities", force: true do |t|
    t.integer  "user_id"
    t.string   "provider"
    t.string   "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "image_galleries", force: true do |t|
    t.integer "site_id"
    t.integer "field_id"
    t.text    "images"
  end

  create_table "import_jobs", force: true do |t|
    t.string   "status"
    t.string   "original_filename"
    t.datetime "finished_at"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.integer  "user_id"
    t.integer  "collection_id"
    t.text     "exception"
  end

  create_table "instedd_telemetry_counters", force: true do |t|
    t.integer "period_id"
    t.string  "bucket"
    t.text    "key_attributes"
    t.integer "count",               default: 0
    t.string  "key_attributes_hash"
  end

  add_index "instedd_telemetry_counters", ["bucket", "key_attributes_hash", "period_id"], name: "instedd_telemetry_counters_unique_fields", unique: true, using: :btree

  create_table "instedd_telemetry_periods", force: true do |t|
    t.datetime "beginning"
    t.datetime "end"
    t.datetime "stats_sent_at"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "lock_owner"
    t.datetime "lock_expiration"
  end

  create_table "instedd_telemetry_set_occurrences", force: true do |t|
    t.integer "period_id"
    t.string  "bucket"
    t.text    "key_attributes"
    t.string  "element"
    t.string  "key_attributes_hash"
  end

  add_index "instedd_telemetry_set_occurrences", ["bucket", "key_attributes_hash", "element", "period_id"], name: "instedd_telemetry_set_occurrences_unique_fields", unique: true, using: :btree

  create_table "instedd_telemetry_settings", force: true do |t|
    t.string "key"
    t.string "value"
  end

  add_index "instedd_telemetry_settings", ["key"], name: "index_instedd_telemetry_settings_on_key", unique: true, using: :btree

  create_table "instedd_telemetry_timespans", force: true do |t|
    t.string   "bucket"
    t.text     "key_attributes"
    t.datetime "since"
    t.datetime "until"
    t.string   "key_attributes_hash"
  end

  add_index "instedd_telemetry_timespans", ["bucket", "key_attributes_hash"], name: "instedd_telemetry_timespans_unique_fields", unique: true, using: :btree

  create_table "layer_histories", force: true do |t|
    t.integer  "collection_id"
    t.string   "name"
    t.boolean  "public"
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.integer  "ord"
    t.datetime "valid_since"
    t.datetime "valid_to"
    t.integer  "layer_id"
    t.integer  "version",                   default: 0
    t.string   "anonymous_user_permission", default: "none"
  end

  add_index "layer_histories", ["layer_id"], name: "index_layer_histories_on_layer_id", using: :btree

  create_table "layer_memberships", force: true do |t|
    t.integer  "layer_id"
    t.boolean  "read",          default: false
    t.boolean  "write",         default: false
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.integer  "membership_id"
  end

  add_index "layer_memberships", ["membership_id"], name: "index_layer_memberships_on_membership_id", using: :btree

  create_table "layers", force: true do |t|
    t.integer  "collection_id"
    t.string   "name"
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.integer  "ord"
    t.string   "anonymous_user_permission", default: "none"
  end

  add_index "layers", ["collection_id"], name: "index_layers_on_collection_id", using: :btree

  create_table "location_permissions", force: true do |t|
    t.string   "action",        default: "read"
    t.integer  "membership_id"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  add_index "location_permissions", ["membership_id"], name: "index_location_permissions_on_membership_id", using: :btree

  create_table "memberships", force: true do |t|
    t.integer  "user_id"
    t.integer  "collection_id"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.boolean  "admin",         default: false
  end

  add_index "memberships", ["collection_id"], name: "index_memberships_on_collection_id", using: :btree
  add_index "memberships", ["user_id"], name: "index_memberships_on_user_id", using: :btree

  create_table "messages", force: true do |t|
    t.string   "guid"
    t.string   "country"
    t.string   "carrier"
    t.string   "channel"
    t.string   "application"
    t.string   "from"
    t.string   "to"
    t.string   "subject"
    t.string   "body"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.text     "reply"
    t.integer  "collection_id"
    t.boolean  "is_send",       default: false
  end

  create_table "name_permissions", force: true do |t|
    t.string   "action",        default: "read"
    t.integer  "membership_id"
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  add_index "name_permissions", ["membership_id"], name: "index_name_permissions_on_membership_id", using: :btree

  create_table "prefixes", force: true do |t|
    t.string   "version"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "reminders", force: true do |t|
    t.string   "name"
    t.text     "reminder_message"
    t.integer  "repeat_id"
    t.integer  "collection_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.boolean  "is_all_site"
    t.text     "schedule"
    t.datetime "next_run"
    t.text     "sites"
    t.boolean  "status"
  end

  add_index "reminders", ["collection_id"], name: "index_reminders_on_collection_id", using: :btree
  add_index "reminders", ["repeat_id"], name: "index_reminders_on_repeat_id", using: :btree

  create_table "repeats", force: true do |t|
    t.string   "name"
    t.integer  "order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text     "rule"
  end

  create_table "share_channels", force: true do |t|
    t.integer  "channel_id"
    t.integer  "collection_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "site_histories", force: true do |t|
    t.integer  "collection_id"
    t.string   "name"
    t.decimal  "lat",                       precision: 10, scale: 6
    t.decimal  "lng",                       precision: 10, scale: 6
    t.datetime "created_at",                                                               null: false
    t.datetime "updated_at",                                                               null: false
    t.text     "properties"
    t.string   "location_mode",  limit: 10,                          default: "automatic"
    t.string   "id_with_prefix"
    t.datetime "valid_since"
    t.datetime "valid_to"
    t.integer  "site_id"
    t.string   "uuid"
    t.integer  "version",                                            default: 0
    t.integer  "user_id"
  end

  add_index "site_histories", ["site_id"], name: "index_site_histories_on_site_id", using: :btree

  create_table "site_reminders", force: true do |t|
    t.integer  "reminder_id"
    t.integer  "site_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "site_reminders", ["reminder_id"], name: "index_site_reminders_on_reminder_id", using: :btree
  add_index "site_reminders", ["site_id"], name: "index_site_reminders_on_site_id", using: :btree

  create_table "sites", force: true do |t|
    t.integer  "collection_id"
    t.string   "name"
    t.decimal  "lat",                       precision: 10, scale: 6
    t.decimal  "lng",                       precision: 10, scale: 6
    t.datetime "created_at",                                                               null: false
    t.datetime "updated_at",                                                               null: false
    t.text     "properties"
    t.string   "location_mode",  limit: 10,                          default: "automatic"
    t.string   "id_with_prefix"
    t.string   "uuid"
    t.integer  "version",                                            default: 0
    t.datetime "deleted_at"
  end

  add_index "sites", ["collection_id"], name: "index_sites_on_collection_id", using: :btree
  add_index "sites", ["deleted_at"], name: "index_sites_on_deleted_at", using: :btree

  create_table "sites_permissions", force: true do |t|
    t.integer  "membership_id"
    t.string   "type"
    t.boolean  "all_sites",     default: true
    t.text     "some_sites"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  create_table "snapshots", force: true do |t|
    t.string   "name"
    t.datetime "date"
    t.integer  "collection_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "thresholds", force: true do |t|
    t.integer  "ord"
    t.string   "color"
    t.text     "conditions"
    t.integer  "collection_id"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.string   "name"
    t.boolean  "is_all_site"
    t.text     "sites"
    t.boolean  "is_all_condition"
    t.boolean  "is_notify"
    t.text     "phone_notification"
    t.text     "email_notification"
    t.string   "message_notification"
  end

  create_table "user_snapshots", force: true do |t|
    t.integer  "user_id"
    t.integer  "snapshot_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.integer  "collection_id"
  end

  create_table "users", force: true do |t|
    t.string   "email",                              default: "", null: false
    t.string   "encrypted_password",     limit: 128, default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                      default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.string   "phone_number"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.boolean  "is_super_user"
    t.string   "authentication_token"
    t.integer  "collection_count",                   default: 0
    t.integer  "layer_count",                        default: 0
    t.integer  "site_count",                         default: 0
    t.integer  "gateway_count",                      default: 0
    t.boolean  "success_outcome"
  end

  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
