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

ActiveRecord::Schema[8.0].define(version: 2025_06_08_080213) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "app_preferences", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.integer "pref_type"
    t.string "value"
    t.bigint "collection_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id"], name: "index_app_preferences_on_collection_id"
  end

  create_table "checkouts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "collection_options", force: :cascade do |t|
    t.string "value", null: false
    t.bigint "collection_question_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_question_id"], name: "index_collection_options_on_collection_question_id"
  end

  create_table "collection_questions", force: :cascade do |t|
    t.bigint "collection_id", null: false
    t.string "question", null: false
    t.boolean "required", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "question_type"
    t.index ["collection_id"], name: "index_collection_questions_on_collection_id"
  end

  create_table "collections", force: :cascade do |t|
    t.string "division"
    t.string "admin_group"
    t.text "description"
    t.string "division_page_url"
    t.string "link_to_policies"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "identifications", force: :cascade do |t|
    t.string "type_status"
    t.string "identified_by"
    t.string "date_identified"
    t.text "identification_remarks"
    t.string "scientific_name"
    t.string "scientific_name_authorship"
    t.string "kingdom"
    t.string "phylum"
    t.string "class_name"
    t.string "order_name"
    t.string "family"
    t.string "genus"
    t.string "specific_epithet"
    t.string "infraspecific_epithet"
    t.string "taxon_rank"
    t.string "vernacular_name"
    t.bigint "item_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "current", default: false, null: false
    t.index ["item_id"], name: "index_identifications_on_item_id"
  end

  create_table "information_requests", force: :cascade do |t|
    t.string "send_to"
    t.string "checkout_items"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_information_requests_on_user_id"
  end

  create_table "items", force: :cascade do |t|
    t.string "occurrence_id"
    t.string "catalog_number"
    t.date "modified"
    t.string "recorded_by"
    t.integer "individual_count"
    t.string "sex"
    t.string "life_stage"
    t.string "reproductive_condition"
    t.string "vitality"
    t.string "other_catalog_numbers"
    t.text "occurrence_remarks"
    t.text "organism_remarks"
    t.string "associated_sequences"
    t.string "field_number"
    t.date "event_date_start"
    t.date "event_date_end"
    t.string "verbatim_event_date"
    t.string "sampling_protocol"
    t.text "event_remarks"
    t.string "continent"
    t.string "country"
    t.string "state_province"
    t.string "county"
    t.string "locality"
    t.string "verbatim_locality"
    t.string "verbatim_elevation"
    t.float "minimum_elevation_in_meters"
    t.float "maximum_elevation_in_meters"
    t.float "decimal_latitude"
    t.float "decimal_longitude"
    t.float "coordinate_uncertainty_in_meters"
    t.string "verbatim_coordinates"
    t.string "georeferenced_by"
    t.date "georeferenced_date"
    t.string "geodetic_datum"
    t.string "georeference_protocol"
    t.bigint "collection_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id"], name: "index_items_on_collection_id"
  end

  create_table "loan_answers", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "loan_question_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["loan_question_id"], name: "index_loan_answers_on_loan_question_id"
    t.index ["user_id"], name: "index_loan_answers_on_user_id"
  end

  create_table "loan_questions", force: :cascade do |t|
    t.string "question"
    t.integer "question_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "required"
  end

  create_table "map_fields", force: :cascade do |t|
    t.string "table"
    t.string "specify_field"
    t.string "rails_field"
    t.string "caption"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "options", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "value"
    t.bigint "loan_question_id", null: false
    t.index ["loan_question_id"], name: "index_options_on_loan_question_id"
  end

  create_table "preparations", force: :cascade do |t|
    t.string "prep_type"
    t.integer "count"
    t.string "barcode"
    t.string "description"
    t.bigint "item_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_preparations_on_item_id"
  end

  create_table "requestables", force: :cascade do |t|
    t.bigint "preparation_id", null: false
    t.bigint "checkout_id", null: false
    t.integer "count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["checkout_id"], name: "index_requestables_on_checkout_id"
    t.index ["preparation_id"], name: "index_requestables_on_preparation_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "principal_name"
    t.string "display_name"
    t.string "affiliation"
    t.string "first_name"
    t.string "last_name"
    t.string "orcid"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "app_preferences", "collections"
  add_foreign_key "collection_options", "collection_questions"
  add_foreign_key "collection_questions", "collections"
  add_foreign_key "identifications", "items"
  add_foreign_key "information_requests", "users"
  add_foreign_key "items", "collections"
  add_foreign_key "loan_answers", "loan_questions"
  add_foreign_key "loan_answers", "users"
  add_foreign_key "options", "loan_questions"
  add_foreign_key "preparations", "items"
  add_foreign_key "requestables", "checkouts"
  add_foreign_key "requestables", "preparations"
end
