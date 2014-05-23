require 'directory_service'

class DukeDirectoryService < DirectoryService

  DUID_ATTRIBUTE = "dudukeid"

  NETID_ATTRIBUTE = "uid"

  def result_class
    DukeDirectoryService::Result
  end

  def netid_search(query)
    search Filters.netid(query)
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

  class Filters < DirectoryService::Filters
    def self.duid(query)
      filter :eq, DUID_ATTRIBUTE, query
    end

    def self.netid(query)
      filter :eq, NETID_ATTRIBUTE, query
    end

    def self.netid_or_duid(query)
      netid(query) | duid(query)
    end
  end

end
