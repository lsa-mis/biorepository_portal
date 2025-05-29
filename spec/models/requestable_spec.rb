# == Schema Information
#
# Table name: requestables
#
#  id             :bigint           not null, primary key
#  count          :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  checkout_id    :bigint           not null
#  preparation_id :bigint           not null
#
# Indexes
#
#  index_requestables_on_checkout_id     (checkout_id)
#  index_requestables_on_preparation_id  (preparation_id)
#
# Foreign Keys
#
#  fk_rails_...  (checkout_id => checkouts.id)
#  fk_rails_...  (preparation_id => preparations.id)
#
require 'rails_helper'

RSpec.describe Requestable, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
