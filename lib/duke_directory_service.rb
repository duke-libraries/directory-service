require 'directory_service'

class DukeDirectoryService < DirectoryService

  DUID_ATTRIBUTE = "dudukeid"
  HOST = "ldap.duke.edu"
  BASE = "ou=people,dc=duke,dc=edu"
  SSL_PORT = 636

  def initialize(config={})
    super
    @host ||= HOST
    @base ||= BASE
    @port ||= SSL_PORT unless @username.nil?
  end

  def find_by_netid(netid, args={})
    find_by_uid(netid, args)
  end

  def find_by_duid(duid, args={})
    search_one_result Net::LDAP::Filter.eq(DUID_ATTRIBUTE, duid), args
  end

  class Result < DirectoryService::Result
    def netid
      send NETID_ATTRIBUTE
    end

    def duid
      send DUID_ATTRIBUTE
    end
  end

  protected

  def result_class
    DukeDirectoryService::Result
  end

end
