#!/usr/bin/env ruby
# vim: fdm=marker ts=2 sw=2
# author:     Michael Brailsford
# created:    2015-08-28 00:20:12 -0500
# contents:   

require 'nokogiri'
require_relative 'pom'

def search_up_for(filename, opt_hsh = {})
  dir       = File.absolute_path (opt_hsh.has_key? :start_dir) ? opt_hsh[:start_dir] : Dir.pwd
  exclusive = (opt_hsh.has_key? :exclusive) ? opt_hsh[:exclusive] : true

  while dir.start_with? Dir.home
    if exclusive
        dir = File.dirname dir
        break if File.exists? "#{dir}/#{filename}"
    else
        break if File.exists? "#{dir}/#{filename}"
        dir = File.dirname dir
    end
  end

  return nil unless dir.start_with? Dir.home
  dir
end

##
# Find the parent pom, assuming the pom in the current directory is the parent and then searching up the directory tree
# if that is not that case.
#{{{
def find_project_root_directory
  dir_with_pom = search_up_for("pom.xml")
  return nil if dir_with_pom.nil?

  pom = POM.new "#{dir_with_pom}/pom.xml"
  while pom.has_parent?
    if dir_with_pom == Dir.home
      dir_with_pom = nil
      break
    end

    dir_with_pom = search_up_for("pom.xml", {start_dir: dir_with_pom})
    pom = POM.new "#{dir_with_pom}/pom.xml"
  end
  dir_with_pom
end
#}}}
