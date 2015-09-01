#!/usr/bin/env ruby
# vim: fdm=marker ts=2 sw=2
# author:     Michael Brailsford
# created:    2015-08-28 00:20:12 -0500
# contents:   

#{{{
def search_up_for(filename, opt_hsh = {})
  dir       = File.absolute_path (opt_hsh.has_key? :start_dir) ? opt_hsh[:start_dir] : Dir.pwd
  exclusive = (opt_hsh.has_key? :exclusive) ? opt_hsh[:exclusive] : true

  while dir.start_with? Dir.home
    if exclusive
        dir = File.dirname dir
        return dir if File.exists? "#{dir}/#{filename}"
    else
        puts "#{dir}/#{filename}"
        return dir if File.exists? "#{dir}/#{filename}"
        dir = File.dirname dir
    end
  end
  nil
end
#}}}

