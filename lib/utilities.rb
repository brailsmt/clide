#!/usr/bin/env ruby
# vim: fdm=marker ts=2 sw=2
# author:     Michael Brailsford
# created:    2015-08-28 00:20:12 -0500
# contents:   

require 'pathname'

#{{{
def search_up_for(filename, opt_hsh = {})
  dir      = Pathname.new(opt_hsh[:start_dir] || Pathname::pwd)
  stop_dir = Pathname.new(opt_hsh[:stop_dir] || ENV['HOME'])

  poms = []
  dir.ascend { |path|
      pom = path + filename
      poms << path if pom.exist?
      puts path.realpath
      puts stop_dir.realpath
      break if path.realpath == stop_dir.realpath
  }
  poms
end
#}}}

