require 'net-ldap'

class DirectoryService

  attr_reader :host, :port, :auth
  attr_accessor :base, :scope, :attributes
  
  DEFAULT_SCOPE = Net::LDAP::SearchScope_SingleLevel

  EPPN_ATTRIBUTE = "edupersonprincipalname"

  class Error < StandardError; end
  class MultipleResultsError < Error; end
  class NoResultsError < Error; end

  def initialize(config={})
    @host = config.fetch(:host, ENV['DIRECTORY_HOST'])
    @base = config.fetch(:base, ENV['DIRECTORY_BASE'])
    @scope = config.fetch(:scope, ENV['DIRECTORY_SCOPE']) || DEFAULT_SCOPE
    @port = config.fetch(:port, ENV['DIRECTORY_PORT']) # default LDAP port if nil
    @username = config.fetch(:username, ENV['DIRECTORY_USER'])
    @password = config.fetch(:password, ENV['DIRECTORY_PASS'])
    @auth = {method: :simple, username: @username, password: @password} if @username
    @attributes = config[:attributes] # nil or empty array retrieves all attributes
    yield self if block_given?
  end

  def inspect
    "#<#{self.class.name}: @host=#{host} @port=#{port} @base=#{base} @scope=#{scope}>"
  end

  def search(filter, args={})
    args.merge!(filter: filter)
    args[:attributes] ||= attributes
    _search(args)
  rescue Net::LDAP::LdapError => e
    raise Error, "LDAP error: #{e.message}"
  end

  def name_search(name, args={})
    search Net::LDAP::Filter.contains("cn", name), args
  end

  def find_by_uid(uid, args={})
    search_one_result Net::LDAP::Filter.eq("uid", uid), args
  end

  def find_by_eppn(eppn, args={})
    search_one_result Net::LDAP::Filter.eq(EPPN_ATTRIBUTE, eppn), args
  end

  def search_one_result(filter, args={})
    results = search(filter, args)
    raise NoResultsError, "No results for query: #{filter.inspect}" if results.empty?
    raise MultipleResultsError, "Unexpected multiple results for query: #{filter.inspect}" if results.size > 1
    results.first
  end

  # A directory search result
  class Result
    attr_reader :ldap_entry

    # ldap_entry is a Net::LDAP::Entry instance
    def initialize(ldap_entry)
      @ldap_entry = ldap_entry
    end

    def [](attr_name)
      ldap_entry[attr_name]
    end

    def first_value(attr_name)
      values = self[attr_name]
      values && values.first
    end

    def first_values
      ldap_entry.attribute_names.each_with_object({}) { |attr, memo| memo[attr] = first_value(attr) }
    end

    def has_attribute?(attr_name)
      ldap_entry.attribute_names.include? attr_name.to_sym
    end

    def method_missing(method, *args)
      return self[method.to_s] if has_attribute?(method)
      super
    end
  end

  protected

  def result_class
    Result
  end

  private

  def ldap_config
    {host: host, base: base, scope: scope, auth: auth}
  end

  def client
    Net::LDAP.new ldap_config
  end

  def _search(args={})
    logger.debug "#{self.class.to_s} search with argments: #{args}"
    results = []
    client.search(args) do |result|
      results << result_class.new(result)
    end
    results
  end

end
