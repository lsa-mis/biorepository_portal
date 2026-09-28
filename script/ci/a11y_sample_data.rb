# Populates the test database with enough public content for the Axcess
# accessibility crawl to reach real markup: collections, items with
# preparations and identifications, and FAQs. db/seeds.rb creates none of
# these, so without this script most public pages render their empty states.
#
# Usage: RAILS_ENV=test bin/rails runner script/ci/a11y_sample_data.rb
require "factory_bot_rails"

if Collection.exists?
  puts "a11y sample data: collections already present, skipping"
  exit
end

Faker::Config.random = Random.new(42)

collections = [
  { division: "Herpetology", admin_group: "a11y-ci-herpetology" },
  { division: "Mammals", admin_group: "a11y-ci-mammals" }
].map do |attrs|
  FactoryBot.create(
    :collection,
    **attrs,
    short_description: "#{attrs[:division]} specimens available for research loans.",
    long_description: "<p>The #{attrs[:division]} collection holds preserved and frozen tissue specimens.</p>",
    division_page_url: "https://lsa.umich.edu/ummz",
    link_to_policies: "https://lsa.umich.edu/ummz"
  )
end

species = [
  ["Lithobates catesbeianus", "American bullfrog"],
  ["Thamnophis sirtalis", "Common garter snake"],
  ["Chrysemys picta", "Painted turtle"],
  ["Ambystoma maculatum", "Spotted salamander"],
  ["Peromyscus leucopus", "White-footed mouse"],
  ["Sciurus carolinensis", "Eastern gray squirrel"],
  ["Procyon lotor", "Raccoon"],
  ["Myotis lucifugus", "Little brown bat"]
].each

collections.each do |collection|
  4.times do
    scientific_name, vernacular_name = species.next
    item = FactoryBot.create(:item, collection: collection)
    FactoryBot.create(:identification, item: item, scientific_name: scientific_name,
                                       vernacular_name: vernacular_name)
    FactoryBot.create(:preparation, item: item, prep_type: "Tissue", barcode: "BC-#{item.id}",
                                    description: "Frozen tissue sample")
  end
end

[
  ["How do I request a loan?", "Sign in, add preparations to your checkout, and complete the loan request form."],
  ["Who can borrow specimens?", "Researchers and public health professionals affiliated with a recognized institution."],
  ["How long does a request take?", "Most requests are reviewed within two weeks."]
].each do |question, answer|
  Faq.create!(question: question, answer: answer)
end

puts "a11y sample data: #{Collection.count} collections, #{Item.count} items, #{Faq.count} FAQs"
