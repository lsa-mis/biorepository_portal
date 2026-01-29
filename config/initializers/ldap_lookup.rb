LdapLookup.configuration do |config|
  # Server Configuration (defaults work for UM LDAP)
  config.host = ENV.fetch('LDAP_HOST', 'ldap.umich.edu')
  config.port = ENV.fetch('LDAP_PORT', '389')
  config.base = ENV.fetch('LDAP_BASE', 'dc=umich,dc=edu')

  # Authentication (optional for anonymous binds)
  # Leave unset to use anonymous binds (if your LDAP server allows it)
  # config.username = ENV['LDAP_USERNAME']
  config.password = ENV['LDAP_PASSWORD']

  # If using a service account with custom bind DN, uncomment and set:
  config.bind_dn = ENV['LDAP_BIND_DN']
  # Note: LDAP_BIND_DN replaces LDAP_USERNAME (LDAP_USERNAME can be unset), not LDAP_PASSWORD.

  # Encryption - REQUIRED (defaults to STARTTLS)
  config.encryption = ENV.fetch('LDAP_ENCRYPTION', 'start_tls').to_sym
  # Use :simple_tls for LDAPS on port 636
  # TLS verification (defaults to true). Set LDAP_TLS_VERIFY=false only for local testing.
  # Optional custom CA bundle: set LDAP_CA_CERT=/path/to/ca-bundle.pem

  # Optional: Attribute Configuration
  config.dept_attribute = ENV.fetch('LDAP_DEPT_ATTRIBUTE', 'umichPostalAddressData')
  config.group_attribute = ENV.fetch('LDAP_GROUP_ATTRIBUTE', 'umichGroupEmail')

  # Optional: Logger for debug output (responds to debug/info or call)
  # config.logger = Rails.logger

  # Optional: Separate search bases for users and groups (UM service accounts)
  # config.user_base = ENV.fetch('LDAP_USER_BASE', 'ou=people,dc=umich,dc=edu')
  # config.group_base = ENV.fetch('LDAP_GROUP_BASE', 'ou=user groups,ou=groups,dc=umich,dc=edu')
end
