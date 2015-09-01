#!/usr/bin/env ruby
# vim: fdm=marker ts=2 sw=2
# author:     Michael Brailsford
# created:    2015-08-23 06:09:24 -0500
# contents:   A clide utility to parse a maven pom and provide useful information about a project.

require 'nokogiri'
require 'parseconfig'
require 'pp'
require 'digest'
require_relative 'utilities'
require_relative 'config'

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
  CONF = ClideConfig.instance

  attr_accessor :pom, :group_id, :project_id, :version, :is_parent
  attr_accessor :project_root, :filename, :namespaces, :dependencies, :modules

  def initialize(fname)
    return unless File.exists? fname
    
    @filename     = fname
    @project_root = File.dirname(File.absolute_path(@filename))

    @pom          = Nokogiri::XML(File.open(@filename, 'r'))
    @namespaces   = @pom.namespaces
    @namespaces   = { 'xmlns' => 'http://maven.apache.org/POM/4.0.0' } if @namespaces.empty?
    @is_parent    = ! has_parent?
    @modules      = @pom.xpath "//xmlns:modules/xmlns:module/text()", @namespaces

    init_dependencies
  end

  def init_dependencies
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

  def has_parent?
    return true if @pom == nil
    parent = @pom.xpath "//xmlns:parent", @namespaces
    !parent.empty?
  end

  def update_md5
      puts CONF[:pom_md5]
      File.open(CONF[:pom_md5], 'w+') { |file|
          modules.each { |m|
              pom = "#{m}/pom.xml"
              puts "#{pom} #{Digest::MD5.file pom}"

              file.puts "#{pom} #{Digest::MD5.file pom}"
          }
      }
  end

  def poms_have_been_updated?
    return true unless File.exists? CONF[:pom_md5]

    File.open(CONF[:pom_md5], 'r').each_line { |line|
        (pom_fname, previous_md5) = line.split %r{\s+}
        current_md5 = Digest::MD5.file pom_fname

        return true if current_md5 != previous_md5
    }
    false
  end

  def epom_fname
    ".clide/epom.xml"
  end

  private :epom_fname, :init_dependencies, :has_parent?
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

    `mvn help:effective-pom -Doutput=#{CONF[:effective_pom]}`
end
#}}}

#{{{
def load_effective_pom
    return POM.new EPOM_FNAME if File.exists? EPOM_FNAME
    
    build_effective_pom
end
#}}}

##
# Find the parent pom, assuming the pom in the current directory is the parent and then searching up the directory tree
# if that is not that case.
#{{{
def find_project_root_directory
    dir_with_pom = search_up_for("pom.xml")
    return nil if dir_with_pom.nil?

    pom = POM.new "#{dir_with_pom}/pom.xml"
    while not pom.is_parent?
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
