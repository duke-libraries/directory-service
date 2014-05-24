require 'directory_service'

class DukeDirectoryService < DirectoryService

  class Error < DirectoryService::Error; end

  DUID_ATTRIBUTE = "dudukeid"
  NETID_ATTRIBUTE = "uid"
  HOST = "ldap.duke.edu"
  BASE = "ou=people,dc=duke,dc=edu"
  SSL_PORT = 636

  def initialize(config={})
    super
    @host ||= HOST
    @base ||= BASE
    @port ||= SSL_PORT unless @username.nil?
  end

  def netid_search(netid, args={})
    search_one_result Net::LDAP::Filter.eq(NETID_ATTRIBUTE, netid), args
  rescue DirectoryService::Error => e
    raise Error, e.message
  end

  class Result < DirectoryService::Result
    def netid
      send NETID_ATTRIBUTE
    end

    def duid
      send DUID_ATTRIBUTE
    end

    def duke_unique_id
      duid
    end
  end

  protected

  def result_class
    DukeDirectoryService::Result
  end

end
