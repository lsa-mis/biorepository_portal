LdapLookup.configuration do |config|
  config.host = "ldap.umich.edu"
  config.port =   "389" 
  config.base =   "dc=umich,dc=edu"
  config.dept_attribute =  "umichPostalAddressData"
  config.group_attribute =   "umichGroupEmail"
end
