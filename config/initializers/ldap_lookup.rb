LdapLookup.configuration do |config|
  config.host = ENV.fetch('LDAP_HOST', 'ldap.umich.edu')
  config.port = ENV.fetch('LDAP_PORT', '389')
  config.base = ENV.fetch('LDAP_BASE', 'dc=umich,dc=edu')

  # Optional: set for authenticated binds
  config.username = ENV['LDAP_USERNAME']
  config.password = ENV['LDAP_PASSWORD']

  # Encryption - REQUIRED
  config.encryption = ENV.fetch('LDAP_ENCRYPTION', 'start_tls').to_sym

  # Optional: attribute overrides
  config.dept_attribute = ENV.fetch('LDAP_DEPT_ATTRIBUTE', 'umichPostalAddressData')
  config.group_attribute = ENV.fetch('LDAP_GROUP_ATTRIBUTE', 'umichGroupEmail')
end
