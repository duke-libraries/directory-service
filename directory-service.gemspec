Gem::Specification.new do |gem|
  gem.name          = "directory-service"
  gem.platform      = Gem::Platform::RUBY		
  gem.version       = "0.1.0"
  gem.authors       = ["David Chandek-Stark"]
  gem.description   = "A simple wrapper for an LDAP service"
  gem.summary       = "A simple wrapper for an LDAP service"
  gem.files         = ["lib/directory_service.rb", "lib/duke_directory_service.rb"]
  gem.license       = "BSD"
  gem.add_dependency "net-ldap"
  gem.add_development_dependency "rspec"  
end
