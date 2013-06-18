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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130614182031) do

  create_table "activities", :force => true do |t|
    t.integer  "user_id"
    t.integer  "collection_id"
    t.integer  "layer_id"
    t.integer  "field_id"
    t.integer  "site_id"
    t.text     "data"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.string   "item_type"
    t.string   "action"
  end

  create_table "channels", :force => true do |t|
    t.string   "name"
    t.boolean  "is_enable"
    t.string   "password"
    t.string   "nuntium_channel_name"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
    t.integer  "user_id"
    t.boolean  "basic_setup"
    t.boolean  "advanced_setup"
    t.boolean  "national_setup"
  end

  create_table "collections", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.boolean  "public"
    t.datetime "created_at",                                                :null => false
    t.datetime "updated_at",                                                :null => false
    t.decimal  "lat",         :precision => 10, :scale => 6
    t.decimal  "lng",         :precision => 10, :scale => 6
    t.decimal  "min_lat",     :precision => 10, :scale => 6
    t.decimal  "min_lng",     :precision => 10, :scale => 6
    t.decimal  "max_lat",     :precision => 10, :scale => 6
    t.decimal  "max_lng",     :precision => 10, :scale => 6
    t.string   "icon"
    t.integer  "quota",                                      :default => 0
  end

  create_table "field_histories", :force => true do |t|
    t.integer  "collection_id"
    t.integer  "layer_id"
    t.string   "name"
    t.string   "code"
    t.string   "kind"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.text     "config"
    t.integer  "ord"
    t.datetime "valid_since"
    t.datetime "valid_to"
    t.integer  "field_id"
    t.text     "metadata"
  end

  add_index "field_histories", ["field_id"], :name => "index_field_histories_on_field_id"

  create_table "fields", :force => true do |t|
    t.integer  "collection_id"
    t.integer  "layer_id"
    t.string   "name"
    t.string   "code"
    t.string   "kind"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.text     "config"
    t.integer  "ord"
    t.text     "metadata"
  end

  create_table "import_jobs", :force => true do |t|
    t.string   "status"
    t.string   "original_filename"
    t.datetime "finished_at"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
    t.integer  "user_id"
    t.integer  "collection_id"
    t.text     "exception"
  end

  create_table "layer_histories", :force => true do |t|
    t.integer  "collection_id"
    t.string   "name"
    t.boolean  "public"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.integer  "ord"
    t.datetime "valid_since"
    t.datetime "valid_to"
    t.integer  "layer_id"
  end

  add_index "layer_histories", ["layer_id"], :name => "index_layer_histories_on_layer_id"

  create_table "layer_memberships", :force => true do |t|
    t.integer  "collection_id"
    t.integer  "user_id"
    t.integer  "layer_id"
    t.boolean  "read",          :default => false
    t.boolean  "write",         :default => false
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
  end

  create_table "layers", :force => true do |t|
    t.integer  "collection_id"
    t.string   "name"
    t.boolean  "public"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.integer  "ord"
  end

  create_table "memberships", :force => true do |t|
    t.integer  "user_id"
    t.integer  "collection_id"
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
    t.boolean  "admin",         :default => false
  end

  create_table "messages", :force => true do |t|
    t.string   "guid"
    t.string   "country"
    t.string   "carrier"
    t.string   "channel"
    t.string   "application"
    t.string   "from"
    t.string   "to"
    t.string   "subject"
    t.string   "body"
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
    t.text     "reply"
    t.integer  "collection_id"
    t.boolean  "is_send",       :default => false
  end

  create_table "prefixes", :force => true do |t|
    t.string   "version"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "reminders", :force => true do |t|
    t.string   "name"
    t.text     "reminder_message"
    t.integer  "repeat_id"
    t.integer  "collection_id"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
    t.boolean  "is_all_site"
    t.text     "schedule"
    t.datetime "next_run"
    t.text     "sites"
    t.boolean  "status"
  end

  add_index "reminders", ["collection_id"], :name => "index_reminders_on_collection_id"
  add_index "reminders", ["repeat_id"], :name => "index_reminders_on_repeat_id"

  create_table "repeats", :force => true do |t|
    t.string   "name"
    t.integer  "order"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.text     "rule"
  end

  create_table "share_channels", :force => true do |t|
    t.integer  "channel_id"
    t.integer  "collection_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "site_histories", :force => true do |t|
    t.integer  "collection_id"
    t.string   "name"
    t.decimal  "lat",                          :precision => 10, :scale => 6
    t.decimal  "lng",                          :precision => 10, :scale => 6
    t.integer  "parent_id"
    t.string   "hierarchy"
    t.datetime "created_at",                                                                           :null => false
    t.datetime "updated_at",                                                                           :null => false
    t.text     "properties"
    t.string   "location_mode",  :limit => 10,                                :default => "automatic"
    t.string   "id_with_prefix"
    t.datetime "valid_since"
    t.datetime "valid_to"
    t.integer  "site_id"
    t.string   "uuid"
  end

  add_index "site_histories", ["site_id"], :name => "index_site_histories_on_site_id"

  create_table "site_reminders", :force => true do |t|
    t.integer  "reminder_id"
    t.integer  "site_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "site_reminders", ["reminder_id"], :name => "index_site_reminders_on_reminder_id"
  add_index "site_reminders", ["site_id"], :name => "index_site_reminders_on_site_id"

  create_table "sites", :force => true do |t|
    t.integer  "collection_id"
    t.string   "name"
    t.decimal  "lat",                          :precision => 10, :scale => 6
    t.decimal  "lng",                          :precision => 10, :scale => 6
    t.integer  "parent_id"
    t.string   "hierarchy"
    t.datetime "created_at",                                                                           :null => false
    t.datetime "updated_at",                                                                           :null => false
    t.text     "properties"
    t.string   "location_mode",  :limit => 10,                                :default => "automatic"
    t.string   "id_with_prefix"
    t.string   "uuid"
  end

  create_table "sites_permissions", :force => true do |t|
    t.integer  "membership_id"
    t.string   "type"
    t.boolean  "all_sites",     :default => true
    t.text     "some_sites"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
  end

  create_table "snapshots", :force => true do |t|
    t.string   "name"
    t.datetime "date"
    t.integer  "collection_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "thresholds", :force => true do |t|
    t.integer  "ord"
    t.string   "color"
    t.text     "conditions"
    t.integer  "collection_id"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
    t.string   "name"
    t.boolean  "is_all_site"
    t.text     "sites"
    t.boolean  "is_all_condition"
    t.boolean  "is_notify"
    t.text     "phone_notification"
    t.text     "email_notification"
    t.string   "message_notification"
  end

  create_table "user_snapshots", :force => true do |t|
    t.integer  "user_id"
    t.integer  "snapshot_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.integer  "collection_id"
  end

  create_table "users", :force => true do |t|
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
    t.string   "phone_number"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.boolean  "is_super_user"
    t.string   "authentication_token"
    t.integer  "collection_count",       :default => 0
    t.integer  "layer_count",            :default => 0
    t.integer  "site_count",             :default => 0
    t.integer  "gateway_count",          :default => 0
    t.boolean  "success_outcome"
  end

  add_index "users", ["confirmation_token"], :name => "index_users_on_confirmation_token", :unique => true
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
