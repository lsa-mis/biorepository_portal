# == Schema Information
#
# Table name: addresses
#
#  id             :bigint           not null, primary key
#  address_line_1 :string
#  address_line_2 :string
#  city           :string
#  country        :string
#  email          :string
#  first_name     :string
#  last_name      :string
#  phone          :string
#  primary        :boolean
#  state          :string
#  zip            :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  user_id        :bigint           not null
#
# Indexes
#
#  index_addresses_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Address < ApplicationRecord
  belongs_to :user

  VALID_EMAIL_REGEX = URI::MailTo::EMAIL_REGEXP

  validates :email, presence: true, format: { with: VALID_EMAIL_REGEX, message: "Please Enter a Valid Email" }
  validates :first_name, :last_name, :address_line_1, :city, :state, :zip, :country, :phone, presence: true

  before_save :unset_other_primaries, if: :primary?

  def full_name
    "#{first_name} #{last_name}"
  end

  private

  def unset_other_primaries # Ensure only one primary address per user
    return unless user # skip if no user

    user.addresses.where.not(id: self.id).update_all(primary: false)
  end
end
