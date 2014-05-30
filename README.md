directory-service
=================

A basic LDAP search service.

Initialize ...

```ruby
> require './lib/directory_service'
 => true 
```

... with hash config

```ruby
> ds = DirectoryService.new(host: "ldap.example.com", base: "dc=example,dc=com")
 => #<DirectoryService: @host=ldap.duke.edu @port= @base=ou=people,dc=duke,dc=edu @scope=1> 
# Other options - :username, :password, :port, :scope
```

... with ENV vars

```sh
$ export DIRECTORY_HOST="ldap.example.com"
$ export DIRECTORY_BASE="dc=example,dc=com"
# Optional - DIRECTORY_PORT, DIRECTORY_SCOPE, DIRECTORY_USER, DIRECTORY_PASS
```

Use with block

```ruby
> DirectoryService.new(host: "ldap.example.com", base: "dc=example,dc=com") do |ds|
>   # do stuff with ds
> end
```

Magic find_by_* methods corresponding to LDAP attribute names

```ruby
> ds.find_by_uid("foobar")
# Returns single result
 => #<DirectoryService::Result:0x007f91019a9a18 @ldap_entry=#<Net::LDAP::Entry:0x007f91019b1740 ...>> 
```

Search with Net::LDAP filters

```ruby
> ds.search(Net::LDAP::Filter.contains("cn", "foobar"))
 => [#<DirectoryService::Result:0x007f910190afa8 ...>, #<DirectoryService::Result:0x007f91018f1440 ...>, #<DirectoryService::Result:0x007f91018e8fc0 ...>, ...
```

Search with string filters (as supported by Net::LDAP)

```ruby
> ds.search("(cn=*coble*)")
 => [#<DirectoryService::Result:0x007f910190afa8 ...>, #<DirectoryService::Result:0x007f91018f1440 ...>, #<DirectoryService::Result:0x007f91018e8fc0 ...>, ...
```
