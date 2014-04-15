require 'net-ldap'

class DirectoryService

  class_attribute :host, :base, :scope, :attributes
  self.scope = Net::LDAP::SearchScope_SingleLevel

  def self.search_results(query)
    client.search(search_args(query)).each_with_object([]) do |result, memo|
      memo << result.attribute_names.each_with_object({}) { |attr, h| h[attr] = result[attr].first }
    end
  end

  def self.configure
    yield self
  end

  def self.search_args(query)
    {filter: filter(query), attributes: attributes}
  end

  def self.filter(query)
    Net::LDAP::Filter.contains("cn", query)
  end

  def self.client
    Net::LDAP.new(host: host, base: base, scope: scope)
  end

  private_class_method :new, :search_args, :filter, :client

end
