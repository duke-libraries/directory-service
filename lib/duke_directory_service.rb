require 'directory_service'

class DukeDirectoryService < DirectoryService

  def netid_or_duid_search(query)
    filter = duid_filter(query) | netid_filter(query)
    search_results_s filter
  end

  def netid_filter(query)
    uid_filter(query)
  end

  def duid_filter(query)
    Net::LDAP::Filter.eq("dudukeid", query)
  end

end
