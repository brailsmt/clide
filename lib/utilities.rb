#!/usr/bin/env ruby
# vim: fdm=marker ts=2 sw=2
# author:     Michael Brailsford
# created:    2015-08-28 00:20:12 -0500
# contents:   

require 'pp'
require 'pathname'
require 'digest'

#{{{
def search_up_for(filename, opt_hsh = {})
  dir      = Pathname.new(opt_hsh[:start_dir] || Pathname::pwd)
  stop_dir = Pathname.new(opt_hsh[:stop_dir] || ENV['HOME'])

  found_files = []
  dir.ascend { |path|
      found_file = path + filename
      found_files << path.realpath if found_file.exist?
      break if path.realpath == stop_dir.realpath
  }
  found_files
end
#}}}
