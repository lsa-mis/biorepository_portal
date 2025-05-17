module SpecHelper

  def mock_login(user)
  info = {
    email: user.email,
    name: user.display_name,
    # uniqname: user.uniqname
  }
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:saml] = OmniAuth::AuthHash.new({
      provider: 'saml',
      uid: '123456',
      info: info
    })
    post user_saml_omniauth_callback_path
    
  end
  
end
