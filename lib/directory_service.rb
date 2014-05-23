require 'net-ldap'

class DirectoryService

  attr_accessor :host, :base, :scope, :attributes
  
  DEFAULT_SCOPE = Net::LDAP::SearchScope_SingleLevel

  def initialize(config={})
    @host = config.fetch :host, ENV['DIRECTORY_HOST']
    @base = config.fetch :base, ENV['DIRECTORY_BASE']
    @scope = config.fetch :scope, DEFAULT_SCOPE
    @attributes = config[:attributes] # nil or empty array retrieves all attributes
    yield self if block_given?
  end

  def result_class
    Result
  end

  def search(filter)
    results = []
    client.search(filter: filter, attribute: attributes) do |result|
      results << result_class.new(result)
    end
    results
  end

  def client
    Net::LDAP.new(host: host, base: base, scope: scope)
  end

  # A directory search result
  class Result
    attr_reader :ldap_entry

    # ldap_entry is a Net::LDAP::Entry instance
    def initialize(ldap_entry)
      @ldap_entry = ldap_entry
    end

    def first_value(attribute)
      ldap_entry[attribute].first
    end

    def attribute_names
      ldap_entry.attrubute_names
    end

    def first_values
      attribute_names.each_with_object({}) { |attr, memo| memo[attr] = first_value(attr) }
    end

    def method_missing(sym, *args)
      retval = ldap_entry.method_missing(sym, *args)
      return retval.first if retval.respond_to? :first
      super
    end
  end

  # Ddirectory search filters
  class Filters
    def self.cn(query)
      filter :contains, "cn", query
    end

    def self.uid(query)
      filter :eq, "uid", query
    end

    def self.eppn(query)
      filter :eq, "edupersonprincipalname", query
    end

    def self.filter(op, attribute, query)
      Net::LDAP::Filter.send(op, attribute, query)
    end
  end

end
