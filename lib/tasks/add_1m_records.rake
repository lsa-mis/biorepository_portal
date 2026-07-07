desc "Add 1 million records to the database."
task add_1m_records: :environment do
  puts "********************************"
  puts "Starting seed — 1,000,000 items with preparations and identifications..."
  puts "This will take roughly 15-25 minutes. Progress shown every 1,000 records."
  insert_records
  puts "Finished adding 1 million records."
  puts "========================================"
  puts "Items:           #{Item.count}"
  puts "Preparations:    #{Preparation.count}"
  puts "Identifications: #{Identification.count}"
  puts "========================================"
end

def insert_records
  puts "Building and inserting Items, Preparations and Identifications batch by batch"

  continents  = ["Africa", "Antarctica", "Asia", "Europe", "North America", "Oceania", "South America"]
  countries   = ["United States", "Canada", "Mexico", "Brazil", "Germany", "Kenya", "Australia", "Japan", "India", "France"]
  life_stages = ["adult", "juvenile", "larva", "egg", "pupa"]
  sexes       = ["male", "female", "unknown"]
  prep_types  = ["skin", "skull", "skeleton", "fluid", "tissue", "whole"]
  kingdoms    = ["Animalia", "Plantae", "Fungi"]
  phylums     = ["Chordata", "Arthropoda", "Mollusca", "Magnoliophyta"]
  classes     = ["Mammalia", "Aves", "Reptilia", "Amphibia", "Insecta"]
  orders      = ["Carnivora", "Primates", "Rodentia", "Passeriformes", "Squamata"]
  families    = ["Felidae", "Canidae", "Accipitridae", "Colubridae", "Muridae"]
  taxon_ranks = ["species", "subspecies", "variety"]
  type_status = ["holotype", "paratype", "syntype", nil]

  collection_ids = Collection.pluck(:id)
  batch_size     = 1_000
  total          = 1_000_000
  batches        = total / batch_size

  batches.times do |i|
    now = Time.current

    items_data = batch_size.times.map do
      {
        catalog_number:     "SEED-#{SecureRandom.hex(6).upcase}",
        collection_id:      collection_ids.sample,
        continent:          continents.sample,
        country:            countries.sample,
        county:             Faker::Address.city,
        state_province:     Faker::Address.state,
        locality:           Faker::Address.street_name,
        decimal_latitude:   rand(-90.0..90.0).round(6),
        decimal_longitude:  rand(-180.0..180.0).round(6),
        event_date_start:   Faker::Date.backward(days: 3650),
        event_date_end:     Faker::Date.backward(days: 365),
        recorded_by:        Faker::Name.name,
        individual_count:   rand(1..20),
        life_stage:         life_stages.sample,
        sex:                sexes.sample,
        vitality:           ["alive", "dead"].sample,
        sampling_protocol:  Faker::Lorem.words(number: 3).join(" "),
        occurrence_remarks: Faker::Lorem.sentence,
        occurrence_id:      Faker::Alphanumeric.unique.alphanumeric(number: 20).downcase,
        created_at:         now,
        updated_at:         now
      }
    end

    result   = Item.insert_all(items_data, returning: [:id])
    item_ids = result.rows.flatten

    preparations_data = item_ids.map do |item_id|
      {
        item_id:     item_id,
        barcode:     "BAR-#{SecureRandom.hex(5).upcase}",
        count:       rand(1..10),
        prep_type:   prep_types.sample,
        description: Faker::Lorem.sentence,
        created_at:  now,
        updated_at:  now
      }
    end
    Preparation.insert_all(preparations_data)

    identifications_data = item_ids.map do |item_id|
      genus   = Faker::Creature::Animal.name.split.first.capitalize
      species = Faker::Lorem.word.downcase
      {
        item_id:                    item_id,
        current:                    true,
        kingdom:                    kingdoms.sample,
        phylum:                     phylums.sample,
        class_name:                 classes.sample,
        order_name:                 orders.sample,
        family:                     families.sample,
        genus:                      genus,
        specific_epithet:           species,
        scientific_name:            "#{genus} #{species}",
        scientific_name_authorship: Faker::Name.last_name,
        taxon_rank:                 taxon_ranks.sample,
        type_status:                type_status.sample,
        identified_by:              Faker::Name.name,
        date_identified:            Faker::Date.backward(days: 1825),
        vernacular_name:            Faker::Creature::Animal.name,
        identification_remarks:     Faker::Lorem.sentence,
        created_at:                 now,
        updated_at:                 now
      }
    end
    Identification.insert_all(identifications_data)

    puts "  Batch #{i + 1}/#{batches} done — #{(i + 1) * batch_size} items, preparations & identifications inserted"
  end

  puts "insert_records complete — all batches processed."
end
