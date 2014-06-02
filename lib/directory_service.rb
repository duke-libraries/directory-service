require 'net-ldap'
require 'json'

class DirectoryService

  attr_reader :host, :port, :auth
  attr_accessor :base, :scope, :attributes
  
  DEFAULT_SCOPE = Net::LDAP::SearchScope_SingleLevel
  SSL_PORT = 636

  class Error < StandardError; end

  def initialize(config={})
    @host = config.fetch(:host, ENV['DIRECTORY_HOST'])
    @base = config.fetch(:base, ENV['DIRECTORY_BASE'])
    @scope = config.fetch(:scope, ENV['DIRECTORY_SCOPE']) || DEFAULT_SCOPE
    @username = config.fetch(:username, ENV['DIRECTORY_USER'])
    @password = config.fetch(:password, ENV['DIRECTORY_PASS'])
    @port = config.fetch(:port, ENV['DIRECTORY_PORT'])
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

  def method_missing(method, *args)
    if method.to_s.start_with?('find_by_') && !args.empty?
      #
      # Map find_by_* methods to search with eq filter, returning first result
      # in similar fashion as ActiveRecord find_by methods.
      #
      # Example: 
      #
      #     find_by_uid("bob")
      #      => search(Net::LDAP::Filter.eq("uid", "bob"), {}).first
      #
      value = args.shift
      attr_name = method.to_s.sub(/^find_by_/, "")
      filter = Net::LDAP::Filter.eq(attr_name, value)
      opts = args.shift || {}
      return search(filter, opts).first
    end
    super
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

    def attribute_names
      ldap_entry.attribute_names
    end

    def first_value(attr_name)
      values = self[attr_name]
      values && values.first
    end

    def to_hash
      attribute_names.each_with_object({}) { |attr, memo| memo[attr] = self[attr] }
    end
    alias_method :attributes, :to_hash

    def to_json
      JSON.generate(to_hash)
    end

    def has_attribute?(attr_name)
      attribute_names.include? attr_name.to_sym
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
    results = []
    client.search(args) do |result|
      results << result_class.new(result)
    end
    results
  end

end
