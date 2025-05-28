class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include ApplicationHelper
  skip_before_action :verify_authenticity_token, only: :saml
  before_action :set_user
  attr_reader :user, :service

  def saml
    handle_auth "Saml"
  end

  private

  def handle_auth(kind)
    if user_signed_in?
      flash[:notice] = "Your #{kind} account was connected."
      redirect_to edit_user_registration_path
    else
      sign_in_and_redirect user, event: :authentication
      $baseURL = ''
      set_flash_message :notice, :success, kind: kind
    end
  end

  def user_is_stale?
    return unless user_signed_in?
    current_user.last_sign_in_at < 15.minutes.ago
  end
end

def auth
  request.env["omniauth.auth"]
end

def set_user
  @user = find_or_create_user
  return unless @user

  uniqname = get_uniqname(@user.email)
  user_membership = find_user_membership(uniqname)

  session[:collection_ids] = determine_collection_ids(user_membership)
  session[:role] = determine_user_role(uniqname, user_membership)
end

private

def find_or_create_user
  return current_user if user_signed_in?

  User.find_by(email: auth.info.email) || create_user
end

def find_user_membership(uniqname)
  access_groups = Collection.pluck(:admin_group).compact
  access_groups.select { |group| LdapLookup.is_member_of_group?(uniqname, group) }
end

def determine_collection_ids(user_membership)
  if user_membership.present?
    Collection.where(admin_group: user_membership).pluck(:id)
  else
    []
  end
end

def determine_user_role(uniqname, user_membership)
  if LdapLookup.is_member_of_group?(uniqname, 'lsa-biorepository-super-admins')
    session[:collection_ids] = Collection.pluck(:id)
    'super_admin'
  elsif user_membership.present?
    'admin'
  else
    'user'
  end
end

def create_user

  @user = User.create(
    email: auth.info.email,
    principal_name: auth.info.principal_name,
    display_name: auth.info.name,
    person_affiliation: auth.info.person_affiliation,
    password: Devise.friendly_token[0, 20]
  )

end
