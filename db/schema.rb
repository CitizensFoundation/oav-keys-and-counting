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

ActiveRecord::Schema.define(version: 20160725111036) do

  create_table "ballots", force: :cascade do |t|
    t.binary   "areas",      limit: 65535, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "budget_ballot_area_translations", force: :cascade do |t|
    t.integer  "budget_ballot_area_id", limit: 4,   null: false
    t.string   "locale",                limit: 255, null: false
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.string   "name",                  limit: 255
  end

  add_index "budget_ballot_area_translations", ["budget_ballot_area_id"], name: "index_budget_ballot_area_translations_on_budget_ballot_area_id", using: :btree
  add_index "budget_ballot_area_translations", ["locale"], name: "index_budget_ballot_area_translations_on_locale", using: :btree

  create_table "budget_ballot_areas", force: :cascade do |t|
    t.float    "budget_amount", limit: 24
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "budget_ballot_item_translations", force: :cascade do |t|
    t.integer  "budget_ballot_item_id", limit: 4,     null: false
    t.string   "locale",                limit: 255,   null: false
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "name",                  limit: 255
    t.text     "description",           limit: 65535
  end

  add_index "budget_ballot_item_translations", ["budget_ballot_item_id"], name: "index_budget_ballot_item_translations_on_budget_ballot_item_id", using: :btree
  add_index "budget_ballot_item_translations", ["locale"], name: "index_budget_ballot_item_translations_on_locale", using: :btree

  create_table "budget_ballots", force: :cascade do |t|
    t.string   "letter",                limit: 255
    t.string   "link",                  limit: 255
    t.float    "price",                 limit: 24
    t.integer  "idea_id",               limit: 4
    t.integer  "budget_ballot_area_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "config", force: :cascade do |t|
    t.string   "rsk_url",                             limit: 255,                   null: false
    t.integer  "timeout_in_seconds",                  limit: 4,                     null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "rsk_soap_username",                   limit: 255
    t.string   "rsk_soap_password",                   limit: 255
    t.string   "election_id",                         limit: 255
    t.string   "saml_assertion_consumer_service_url", limit: 255
    t.string   "saml_idp_sso_target_url",             limit: 255
    t.string   "saml_idp_cert_fingerprint",           limit: 255
    t.string   "saml_name_identifier_format",         limit: 255
    t.string   "rsk_svf_nr",                          limit: 255
    t.boolean  "test_mode",                                         default: false
    t.string   "soap_url",                            limit: 255
    t.text     "public_key",                          limit: 65535
    t.text     "known_x509_cert",                     limit: 65535
    t.text     "areas_imagemap",                      limit: 65535
  end

  create_table "final_split_votes", force: :cascade do |t|
    t.integer  "area_id",                 limit: 4,     null: false
    t.text     "payload_data",            limit: 65535, null: false
    t.integer  "vote_id",                 limit: 4,     null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "encrypted_vote_checksum", limit: 65535, null: false
    t.text     "generated_vote_checksum", limit: 65535, null: false
  end

  add_index "final_split_votes", ["area_id"], name: "index_final_split_votes_on_area_id", using: :btree

  create_table "saml_assertions", force: :cascade do |t|
    t.string   "assertion_id", limit: 255, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "saml_assertions", ["assertion_id"], name: "index_saml_assertions_on_assertion_id", using: :btree

  create_table "votes", force: :cascade do |t|
    t.integer  "area_id",                 limit: 4,     null: false
    t.string   "user_id_hash",            limit: 255,   null: false
    t.text     "payload_data",            limit: 65535, null: false
    t.string   "client_ip_address",       limit: 255,   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "session_id",              limit: 255,   null: false
    t.text     "encrypted_vote_checksum", limit: 65535, null: false
  end

  add_index "votes", ["area_id"], name: "index_votes_on_area_id", using: :btree
  add_index "votes", ["user_id_hash"], name: "index_votes_on_user_id_hash", using: :btree

end
