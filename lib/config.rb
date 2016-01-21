#!/usr/bin/env ruby
# vim: fdm=marker ts=2 sw=2
# author:     Michael Brailsford
# created:    2015-08-23 23:22:09 -0500
# contents:   A module for dealing with clide configuration

require 'singleton'
require 'pathname'
require 'psych'

require_relative 'utilities'

class Pathname
    def external_encoding
        Encoding::UTF_8
    end
end

#{{{
class ClideConfig
  include Singleton

  attr_accessor :params, :project_root

  ##
  # Read the clide configuration file.  If one does not exist, an attempt will be made to find the project root
  # directory from the current working directory up to the user's home directory.
  #{{{
  def initialize
    project_root = Pathname::pwd  # for now clide must be run from the project root

    cliderc = (project_root + (ENV['CLIDERC'] || ".cliderc")).realdirpath

    if cliderc.exist? 
      @params = Psych.load_file cliderc
    else
      @params = {}

      @params[:project_root]      = project_root
      @params[:cliderc]           = cliderc.realdirpath
      @params[:clide_conf_dir]    = (project_root + (ENV['CLIDE_CONF_DIR'] || ".clide"  )).realdirpath

      Dir.mkdir @params[:clide_conf_dir] unless @params[:clide_conf_dir].exist?

      @params[:maven_output_file] = (@params[:clide_conf_dir] + "maven.out").realdirpath
      @params[:pom_md5]           = (@params[:clide_conf_dir] + "pom.md5").realdirpath
      @params[:effective_pom]     = (@params[:clide_conf_dir] + "epom.xml").realdirpath

      # list of all modules in a reactor build, plus the :all module for parent/non-reactor projects
      @params[:modules] = [:all]

      # module specific configuration directories, beneath each module directory, these files will exist
      @params[:module] = {}
      @params[:module][:classpath] = "classpath"
      @params[:module][:deps]      = "dependencies"
      @params[:module][:javasrc]   = "md5"
      @params[:module][:testsrc]   = "test_md5"

      File.open(@params[:cliderc], 'w+') { |rc_file|
        rc_file.write Psych.dump @params
      }
    end
  end
  #}}}

  #{{{
  def [](key)
    @params[key]
  end
  #}}}

  #{{{
  def []=(key, value)
    @params[key] = value
  end
  #}}}

  #{{{
  ##
  # Only update project config under the following circumstances:
  #  - the force argument is specified
  #  - the list of poms and their md5 does not exist
  #  - at least one pom has a different md5 than the last time it was written/checked
  #  - TODO: the sets of pom names in the md5 hash file and the poms in the project are disjoint
  def update(force = false)
    config_outdated = force || !@params[:pom_md5].exist?
    if ! config_outdated
      File.open(@params[:pom_md5], 'r').each_line { |line|
        (previous_md5, pom_fname) = line.split %r{\s+}
        (current_md5, ignored)  = Digest::MD5.file pom_fname

        if current_md5 != previous_md5
          config_outdated = true
          break
        end
      }
    end

    if config_outdated
      load_effective_pom
    end
  end
  #}}}
end
#}}}
