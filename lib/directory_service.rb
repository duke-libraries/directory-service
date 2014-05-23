require 'net-ldap'

class DirectoryService

  attr_accessor :host, :base, :scope, :attributes
  
  DEFAULT_SCOPE = Net::LDAP::SearchScope_SingleLevel
  NETID_ATTRIBUTE = "uid"
  DUID_ATTRIBUTE = "dudukeid"
  NAME_ATTRIBUTE = "cn"

  def initialize(config={})
    @host = config.fetch :host
    @base = config.fetch :base
    @scope = config.fetch :scope, DEFAULT_SCOPE
    @attributes = config[:attributes] # nil or empty array retrieves all attributes
  end

  def search_results(query)
    client.search(search_args(query)).each_with_object([]) do |result, memo|
      memo << result.attribute_names.each_with_object({}) { |attr, h| h[attr] = result[attr].first }
    end
  end

  def self.configure
    yield self
  end

  private

  def search_args(query)
    {filter: combo_filter(query), attributes: attributes}
  end

  def combo_filter(query)
    duid_filter(query) | netid_filter(query) | name_filter(query)
  end

  def name_filter(query)
    Net::LDAP::Filter.contains(NAME_ATTRIBUTE, query)
  end

  def netid_filter(query)
    Net::LDAP::Filter.eq(NETID_ATTRIBUTE, query)
  end

  def duid_filter(query)
    Net::LDAP::Filter.eq(DUID_ATTRIBUTE, query)
  end

  def client
    Net::LDAP.new(host: host, base: base, scope: scope)
  end

end
