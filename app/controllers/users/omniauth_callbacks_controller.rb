class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
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
  if user_signed_in?
    @user = current_user
  elsif User.where(email: auth.info.email).any?
    @user = User.find_by(email: auth.info.email)
  else
    @user = create_user
  end

  # if @user
  #   session[:user_email] = @user.email

  #   if LdapLookup.is_member_of_group?(@user.uniqname, 'lsa-spaceready-developers')
  #     session[:role] = "developer"
  #   elsif LdapLookup.is_member_of_group?(@user.uniqname, 'lsa-spaceready-admins')
  #     session[:role] = "admin"
  #   elsif LdapLookup.is_member_of_group?(@user.uniqname, 'lsa-spaceready-admins-readonly')
  #     session[:role] = "readonly"
  #   elsif  Rover.exists?(uniqname: @user.uniqname)
  #     session[:role] = "rover"
  #   else
  #     session[:role] = "none"
  #   end
  # end
end

def get_uniqname(email)
  email.split("@").first
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
