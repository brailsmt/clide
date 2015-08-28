#!/usr/bin/env ruby
# vim: fdm=marker ts=2 sw=2
# author:     Michael Brailsford
# created:    2015-08-23 06:09:24 -0500
# contents:   Parse a pom.xml and extract useful information

require 'nokogiri'
require 'parseconfig'
require 'pp'
require_relative 'utilities'

EPOM_FNAME=".clide/epom.xml"

##
# Simple class for a single Dependency
#{{{
class Dependency
  attr_accessor :groupId, :artifactId, :version, :scope, :m2_relative_path

  def initialize(pom_dep_node)
    ns = pom_dep_node.namespaces
    @groupId    = pom_dep_node.xpath('./xmlns:groupId/text()', ns).text.strip
    @artifactId = pom_dep_node.xpath('./xmlns:artifactId/text()', ns).text.strip
    @version    = pom_dep_node.xpath('./xmlns:version/text()', ns).text.strip
    @scope      = pom_dep_node.xpath('./xmlns:scope/text()', ns).text.strip
    @scope = 'compile' if @scope.empty?

    grp_path = @groupId.gsub /\./, "/"
    @m2_relative_path = "#{grp_path}/#{@artifactId}/#{@version}"
  end

  def get_maven_coordinate
    "#{@groupId}:#{@artifactId}:#{@version}"
  end

  def get_path_to_dep(m2repo = "#{ENV['HOME']}/.m2/repository")
    "#{m2repo}/#{@m2_relative_path}/#{@artifactId}-#{@version}.jar"
  end
end
#}}}

##
# Manage all things related to a maven pom.
#{{{
class POM
  attr_accessor :raw_pom, :deps, :classpath, :props, :pom
  attr_accessor :group_id, :project_id, :version
  attr_accessor :parent_gid, :parent_pid, :parent_version
  attr_accessor :project_root, :filename, :namespaces, :dependencies

  def initialize(fname)
    return unless File.exists? fname
    @namespaces = { 'xmlns' => 'http://maven.apache.org/POM/4.0.0' }
    @filename = fname
    @project_root = File.dirname(File.absolute_path(@filename))
    @pom = Nokogiri::XML(File.open(@filename, 'r'))
    @dependencies = {}
  end

  def has_parent?
    return true if @pom == nil
    parent = @pom.xpath "//xmlns:parent", @namespaces
    !parent.empty?
  end

  def gen_md5
    # generate md5s for all poms
  end

  def poms_have_been_updated?
    gen_md5 unless File.exists? POM_MD5

    true
  end

  def epom_fname
    ".clide/epom.xml"
  end

  def get_dependencies
    parent = @pom.xpath "//xmlns:project[xmlns:modules]", @namespaces
    projects = @pom.xpath "//xmlns:project[not(xmlns:modules)]", @namespaces

    projects.each { |prj|
      project_name = prj.xpath('./xmlns:name/text()', prj.namespaces).text
      @dependencies[project_name] = []

      prj.xpath("//xmlns:dependencies/xmlns:dependency", prj.namespaces).each { |dep|
        @dependencies[project_name] << Dependency.new(dep)
      }
    }
    @dependencies
  end

  def load_props
  end
end
#}}}

##
# Find the parent pom, assuming the pom in the current directory is the parent and then searching up the directory tree
# if that is not that case.
#{{{
def find_parent_pom
    project_root = find_project_root_directory
    root_pom = "#{project_root}/pom.xml"
    return POM.new root_pom if File.exists? root_pom
    nil
end
#}}}

#{{{
def build_effective_pom
    Dir.mkdir ".clide" unless Dir.exist? ".clide"

    `mvn help:effective-pom -Doutput=#{EPOM_FNAME}`
end
#}}}

#{{{
def load_effective_pom
    return POM.new EPOM_FNAME if File.exists? EPOM_FNAME
    
    build_effective_pom
end
#}}}
