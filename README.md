# LSA SpaceReady
![](https://img.shields.io/badge/Ruby%20Version-3.3.6-red) ![](https://img.shields.io/badge/Rails%20Version-8.0.0-red) ![](https://img.shields.io/badge/Postgresql%20Version-14.10-red)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

The finished application allows researchers and public health professionals to search UMMZ collections and request biological specimens. 

## Getting Started (Mac)

### Prerequisites
- postgresql (correct version and running without errors)
- This application uses University of Michigan Shibboleth + DUO authentication

To get a local copy up and running clone the repo, navigate to the local instance and start the application
```
git clone git@github.com:lsa-mis/biorepository_portal.git
cd biorepository_portal
bundle
bin/rails db:create
bin/rails db:migrate
bin/dev
```

  ## Authentication
  - Omniauth-SAML
    - Shibboleth + DUO
    - Devise

## Support / Questions
  Please email the [LSA W&ADS Rails Team](mailto:lsa-was-rails-devs@umich.edu)
