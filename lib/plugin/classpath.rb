#!/usr/bin/env ruby
# vim: fdm=marker

#TODO:  figure out a uniform way to interface with clide...  use git as model...

require_relative "../config.rb"
require 'pp'

puts Pathname::pwd
puts Pathname::pwd.basename
conf = ClideConfig.read Pathname::pwd
cur_mod = Pathname::pwd.basename
conf[:modules]

#TODO: load cur_mod dependencies
#TODO: load all dependencies
#TODO: print classpath as absolute paths in ~/.m2
