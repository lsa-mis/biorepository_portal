json.extract! identification, :id, :type_status, :identified_by, :date_identified, :identification_remarks, :scientific_name, :scientific_name_authorship, :kingdom, :phylum, :class_name, :order_name, :family, :genus, :specific_epithet, :infraspecific_epithet, :taxon_rank, :vernacular_name, :item_id, :created_at, :updated_at
json.url identification_url(identification, format: :json)
