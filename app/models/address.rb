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

  def shipping_address_string
    string = ""
    string += "#{self.full_name}, #{self.phone}, #{self.email}. "
    string += "#{self.address_line_1}"
    if self.address_line_2.present?
      string += ", #{self.address_line_2}"
    end
    string += ", #{self.city}, #{self.state} #{self.zip}, #{self.country}"
    string
  end

  private

  def unset_other_primaries # Ensure only one primary address per user
    return unless user # skip if no user

    user.addresses.where.not(id: self.id).update_all(primary: false)
  end

  STATES =
    [
      [ 'Alabama', 'AL' ],
      [ 'Alaska', 'AK' ],
      [ 'Arizona', 'AZ' ],
      [ 'Arkansas', 'AR' ],
      [ 'California', 'CA' ],
      [ 'Colorado', 'CO' ],
      [ 'Connecticut', 'CT' ],
      [ 'Delaware', 'DE' ],
      [ 'District of Columbia', 'DC' ],
      [ 'Florida', 'FL' ],
      [ 'Georgia', 'GA' ],
      [ 'Hawaii', 'HI' ],
      [ 'Idaho', 'ID' ],
      [ 'Illinois', 'IL' ],
      [ 'Indiana', 'IN' ],
      [ 'Iowa', 'IA' ],
      [ 'Kansas', 'KS' ],
      [ 'Kentucky', 'KY' ],
      [ 'Louisiana', 'LA' ],
      [ 'Maine', 'ME' ],
      [ 'Maryland', 'MD' ],
      [ 'Massachusetts', 'MA' ],
      [ 'Michigan', 'MI' ],
      [ 'Minnesota', 'MN' ],
      [ 'Mississippi', 'MS' ],
      [ 'Missouri', 'MO' ],
      [ 'Montana', 'MT' ],
      [ 'Nebraska', 'NE' ],
      [ 'Nevada', 'NV' ],
      [ 'New Hampshire', 'NH' ],
      [ 'New Jersey', 'NJ' ],
      [ 'New Mexico', 'NM' ],
      [ 'New York', 'NY' ],
      [ 'North Carolina', 'NC' ],
      [ 'North Dakota', 'ND' ],
      [ 'Ohio', 'OH' ],
      [ 'Oklahoma', 'OK' ],
      [ 'Oregon', 'OR' ],
      [ 'Pennsylvania', 'PA' ],
      [ 'Puerto Rico', 'PR' ],
      [ 'Rhode Island', 'RI' ],
      [ 'South Carolina', 'SC' ],
      [ 'South Dakota', 'SD' ],
      [ 'Tennessee', 'TN' ],
      [ 'Texas', 'TX' ],
      [ 'Utah', 'UT' ],
      [ 'Vermont', 'VT' ],
      [ 'Virginia', 'VA' ],
      [ 'Washington', 'WA' ],
      [ 'West Virginia', 'WV' ],
      [ 'Wisconsin', 'WI' ],
      [ 'Wyoming', 'WY' ]
    ].freeze
    
end
