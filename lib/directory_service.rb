require 'net-ldap'

class DirectoryService

  attr_accessor :host, :base, :scope, :attributes
  
  DEFAULT_SCOPE = Net::LDAP::SearchScope_SingleLevel

  def initialize(config={})
    @host = config.fetch :host, ENV['DIRECTORY_HOST']
    @base = config.fetch :base, ENV['DIRECTORY_BASE']
    @scope = config.fetch :scope, DEFAULT_SCOPE
    @attributes = config[:attributes] # nil or empty array retrieves all attributes
  end

  def search_results(filter)
    client.search(filter: filter, attribute: attributes)
  end

  # Returns search results normalized as hash with string values
  def search_results_s(filter)
    search_results(filter).collect do |entry|
      entry.attribute_names.each_with_object({}) { |attr, memo| memo[attr] = entry[attr].first }
    end
  end

  def name_filter(query)
    Net::LDAP::Filter.contains("cn", query)
  end

  def uid_filter(query)
    Net::LDAP::Filter.eq("uid", query)
  end

  def client
    Net::LDAP.new(host: host, base: base, scope: scope)
  end

end
