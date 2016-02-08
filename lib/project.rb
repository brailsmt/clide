#!/usr/bin/env ruby
# vim: fdm=marker ts=2 sw=2
# author:     Michael Brailsford
# created:    2015-08-23 06:09:24 -0500
# contents:   A clide utility to parse a maven pom and provide useful information about a project.

require 'nokogiri'
require 'pp'
require 'set'
require 'yaml'

require_relative 'utilities'
require_relative 'config'

##
# Simple class for a single Dependency
#{{{
class Dependency
  attr_accessor :groupId, :artifactId, :version, :scope, :m2_relative_path, :coordinate, :key

  def initialize(pom_dep_node)
    ns = pom_dep_node.namespaces
    @groupId    = pom_dep_node.xpath('./xmlns:groupId/text()', ns).text.strip
    @artifactId = pom_dep_node.xpath('./xmlns:artifactId/text()', ns).text.strip
    @key        = "#{@groupId}:#{@artifactId}"
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
    #@md5      = Digest::MD5.file @filename
  end

  def is_out_of_date?
#    src_md5s = Psych.load_file @clide.conf[:source_md5s]
#    new_md5 = Digest::MD5.file @filename
#    if new_md5 == @md5
#      false
#    else
#      @md5 = new_md5
#      true
#    end
  end
  alias_method :recompile?, :is_out_of_date?

  def to_md5
    "#{@md5} #{filename}"
  end
end
#}}}

# This is the xpath to extract the master list of dependencies from the effective pom
DEPENDENCY_MGMT_XPATH = '/projects/xmlns:project/xmlns:dependencyManagement/xmlns:dependencies/xmlns:dependency'

#{{{
class Project
  attr_accessor :key, :deps, :src_dirs, :sources

  def initialize(conf, epom, namespaces = { 'xmlns' => 'http://maven.apache.org/POM/4.0.0' })
    @conf        = conf

    @namespaces  = namespaces
    @groupId     = epom.xpath('/projects/xmlns:project[xmlns:modules]/xmlns:groupId/text()', @namespaces).text.strip

    @dependencies = load_dependencies epom
    @modules      = load_modules epom

    @conf[:modules] = @modules.keys
  end

  def load_dependencies(xml)
    dependencies = {}
    if @conf[:all_dependencies].exist?
      dependencies = Psych.load_file @conf[:all_dependencies]
    else
      @groupId = xml.xpath(DEPENDENCY_MGMT_XPATH, @namespaces).each { |stanza|
        dep = Dependency.new stanza
        dependencies[dep.key] = dep
      }
      Psych.dump dependencies, @conf[:all_dependencies].open("w+")
    end
    dependencies
  end

  def load_modules(xml)
    modules = {}
    xml.xpath('/projects/xmlns:project', @namespaces).each { |pom|
      artifactId = pom.xpath('./xmlns:artifactId/text()', @namespaces).text.strip
      key        = "#{@groupId}:#{artifactId}"

      # create the module directory if needed
      module_dir = @conf[:clide_conf_dir] + artifactId
      module_dir.mkdir unless module_dir.exist?
      depfile = module_dir + "dependencies.yaml"

      modules[artifactId] = {
        dependencies: depfile
      }

      unless depfile.exist?
        deps = []
        depxpath = "./xmlns:dependencies/xmlns:dependency"
        pom.xpath(depxpath, @namespaces).each { |dep|
          gid = dep.xpath("./xmlns:groupId/text()", @namespaces).text.strip
          aid = dep.xpath("./xmlns:artifactId/text()", @namespaces).text.strip
          deps << "#{gid}:#{aid}"
        }
        Psych.dump deps.sort, depfile.open("w+")
      end

      subrc = @conf[:project_root] + artifactId + ".cliderc"
      unless subrc.exist?
        hsh = {
          # this tells clide that this is a sub-project, and must be retained
          parent: @conf[:project_root]
        }
        Psych.dump hsh, subrc.open("w+")
      end
    }
    modules
  end
end
#}}}
