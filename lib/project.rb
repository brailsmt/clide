#!/usr/bin/env ruby
# vim: fdm=marker ts=2 sw=2
# author:     Michael Brailsford
# created:    2015-08-23 06:09:24 -0500
# contents:   A clide utility to parse a maven pom and provide useful information about a project.

require 'nokogiri'
require 'pp'
require 'digest'
require 'psych'
require 'set'

require_relative 'utilities'
require_relative 'config'

##
# Simple class for a single Dependency
#{{{
class Dependency
  attr_accessor :groupId, :artifactId, :version, :scope, :m2_relative_path, :coordinate

  def initialize(pom_dep_node)
    ns = pom_dep_node.namespaces
    @groupId    = pom_dep_node.xpath('./xmlns:groupId/text()', ns).text.strip
    @artifactId = pom_dep_node.xpath('./xmlns:artifactId/text()', ns).text.strip
    @version    = pom_dep_node.xpath('./xmlns:version/text()', ns).text.strip
    @scope      = pom_dep_node.xpath('./xmlns:scope/text()', ns).text.strip
    @scope      = 'compile' if @scope.empty?
    @coordinate = "#{@groupId}:#{@artifactId}:#{@version}"

    grp_path = @groupId.gsub /\./, "/"
    @m2_relative_path = "#{grp_path}/#{@artifactId}/#{@version}"
  end

  def get_path_to_dep(m2repo = "#{ENV['HOME']}/.m2/repository")
    "#{m2repo}/#{@m2_relative_path}/#{@artifactId}-#{@version}.jar"
  end
end
#}}}

##
# Object to manage source file related data/tasks
#{{{
class SourceFile
    attr_reader :filename, :md5

    def initialize(filepath) 
        @filename = filepath
        @md5      = Digest::MD5.file @filename
    end

    def is_out_of_date?
        new_md5 = Digest::MD5.file @filename
        if new_md5 == @md5
            false
        else
            @md5 = new_md5
            true
        end
    end
    alias_method :recompile?, :is_out_of_date?

    def to_md5
        "#{@md5} #{filename}"
    end
end
#}}}

#{{{
class ModuleProject
    attr_reader :name, :src_dirs, :sources

    def initialize(name, modpom, namespaces)
        @namespaces   = namespaces
        @name         = name

        @src_dirs = {
            :main => Pathname.new(modpom.xpath("//xmlns:project[xmlns:artifactId = \"#{@name}\"]/xmlns:build/xmlns:sourceDirectory/text()", @namespaces).text),
            :test => Pathname.new(modpom.xpath("//xmlns:project[xmlns:artifactId = \"#{@name}\"]/xmlns:build/xmlns:testSourceDirectory/text()", @namespaces).text)
        }

        src_glob = "**/*.java"
        @sources = {
          :main => Pathname::glob(@src_dirs[:main] + src_glob).collect { |src| SourceFile.new src },
          :test => Pathname::glob(@src_dirs[:test] + src_glob).collect { |src| SourceFile.new src }
        }
    end
end
#}}}

##
# Object to represent all useful information from a maven pom.
#{{{
class Project

  attr_accessor :pom, :group_id, :project_id, :version, :is_parent
  attr_accessor :filename, :namespaces, :dependencies, :modules
  attr_accessor :module_poms

  def initialize(fname)
    return unless fname.exist?
    conf = ClideConfig.instance
    @module_poms = []
    
    @filename     = fname
    @project_root = conf[:project_root]

    @pom          = Nokogiri::XML(File.open(@filename, 'r'))
    @namespaces   = @pom.namespaces
    @namespaces   = { 'xmlns' => 'http://maven.apache.org/POM/4.0.0' } if @namespaces.empty?
    @is_parent    = ! has_parent?
    @modules      = {}
    @pom.xpath("//xmlns:modules/xmlns:module/text()", @namespaces).each { |mname|
        modsym = artifactId_to_key mname.text
        @modules[modsym] = ModuleProject.new(mname.text, @pom.xpath("//xmlns:project[xmlns:artifactId = \"#{mname}\"]", @namespaces), @namespaces)
    }

    # This will need to be changed in the future for projects which have both modules and src/ directories.
    @sources = nil
    @dependencies = init_dependencies
  end

  def get_all_sources
      all_sources = { :main => [], :test => [] }

      @modules.each { |mname,mod|
          all_sources[:main] += mod.sources[:main]
          all_sources[:test] += mod.sources[:test]
      }
  end

  def artifactId_to_key(artifactId)
      artifactId.gsub(/-/, "_").to_sym
  end

  def key_to_artifactId(key)
      key.to_s.gsub(/_/, "-")
  end

  # TODO:  Refactor this to ProjectModule
  def init_dependencies
    return Hash.new unless ClideConfig.instance.poms_have_been_updated?

    parent = @pom.xpath "//xmlns:project[xmlns:modules]", @namespaces
    projects = @pom.xpath "//xmlns:project/xmlns:modules/xmlns:module/text()", @namespaces

    dependencies = {}
    dependencies[:all] = {}

    projects.each { |prj|
        project_name = artifactId_to_key prj.text
        dependencies[project_name] = Set.new

        prj.xpath("//xmlns:dependencies/xmlns:dependency", prj.namespaces).each { |dep|
            dependency = Dependency.new dep
            dependencies[:all][dependency.coordinate] = dependency
            dependencies[project_name] << dependency.coordinate
        }
    }

    ClideConfig.instance[:dependencies][:file].open('w+') { |file|
        file.write Psych.dump dependencies
    }

    @dependencies
  end

  ##
  # A parent project is one which has 1 or more modules defined in the pom
  def is_parent?
      !@pom.modules.empty?
  end

  def dump_pom_md5s
      md5s = []
      modules.each_key { |m|
          mpom = ClideConfig.instance[:project_root] + (key_to_artifactId m) + 'pom.xml'

          md5s << "#{Digest::MD5.file mpom} #{mpom}"
      }
      md5s
  end

  def dump_source_md5s
  end

  def changed_sources
      @sources.each { |type,srclist|
          srclist.each { |src|
              puts "#{type},#{src}" if src.is_out_of_date?
              puts "." unless src.is_out_of_date?
          }
      }
  end

  private :init_dependencies, :has_parent?
end
#}}}

##
# Load or create the effective pom
#{{{
def load_effective_pom(conf = ClideConfig.instance)
    epomfname = conf[:effective_pom]

    unless epomfname.exist?
        `(cd #{conf[:project_root]}; mvn help:effective-pom -Doutput=#{epomfname})`
    end

    Project.new epomfname
end
#}}}

epom = load_effective_pom
epom.changed_sources
pp epom.modules

#conf[:dependencies].open('w+') { |f|
    #f.puts epom.dependencies.to_yaml
#}
