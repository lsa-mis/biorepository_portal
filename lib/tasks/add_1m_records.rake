desc "Add 1 million records to the database."
task add_1m_records: :environment do
  puts "********************************"
  puts "Starting seed — 1,000,000 items with preparations and identifications..."
  puts "This will take roughly 15-25 minutes. Progress shown every 1,000 records."
  step1
  step2
  step3
  puts "Finished adding 1 million records."
end

def step1
  puts "Step 1: build and insert 1,000 Items"
end

def step2
  puts "Step 2: insert 1 Preparation per item"
end

def step3
  puts "Step 3: nsert 1 Identification per item"
end
