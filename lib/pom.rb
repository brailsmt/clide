#!/usr/bin/env ruby
# vim: fdm=marker ts=2 sw=2
# author:     Michael Brailsford
# created:    2015-08-23 06:09:24 -0500
# contents:   A clide utility to parse a maven pom and provide useful information about a project.

require 'nokogiri'
require 'parseconfig'
require 'pp'
require 'digest'
require 'yaml'
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
    @scope = 'compile' if @scope.empty?
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
# Manage all things related to a maven pom.
#{{{
class POM
  @@conf = ClideConfig.instance

  attr_accessor :pom, :group_id, :project_id, :version, :is_parent
  attr_accessor :project_root, :filename, :namespaces, :dependencies, :modules

  def initialize(fname)
    return unless fname.exist?
    
    @filename     = fname
    @project_root = @@conf[:project_root]

    @pom          = Nokogiri::XML(File.open(@filename, 'r'))
    @namespaces   = @pom.namespaces
    @namespaces   = { 'xmlns' => 'http://maven.apache.org/POM/4.0.0' } if @namespaces.empty?
    @is_parent    = ! has_parent?
    @modules      = @pom.xpath "//xmlns:modules/xmlns:module/text()", @namespaces

    @dependencies = {}
    init_dependencies
  end

  def init_dependencies
    parent = @pom.xpath "//xmlns:project[xmlns:modules]", @namespaces
    projects = @pom.xpath "//xmlns:project[not(xmlns:modules)]", @namespaces

    @dependencies[:all] = {}

    projects.each { |prj|
      project_name = prj.xpath('./xmlns:name/text()', prj.namespaces).text
      @dependencies[project_name] = Set.new

      prj.xpath("//xmlns:dependencies/xmlns:dependency", prj.namespaces).each { |dep|
        dependency = Dependency.new dep
        @dependencies[:all][dependency.coordinate] = dependency
        @dependencies[project_name] << dependency.coordinate
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
      puts @@conf[:pom_md5]
      File.open(@@conf[:pom_md5], 'w+') { |file|
          modules.each { |m|
              mpom = @@conf[:project_root] + m + 'pom.xml'
              puts "#{Digest::MD5.file mpom} #{mpom}"

              file.puts "#{Digest::MD5.file mpom} #{mpom}"
          }
      }
  end

  def poms_have_been_updated?
      return true unless @@conf[:pom_md5].exist?

      File.open(@@conf[:pom_md5], 'r').each_line { |line|
          (previous_md5, pom_fname) = line.split %r{\s+}
          (current_md5, ignored)  = Digest::MD5.file pom_fname

          if current_md5 != previous_md5
              return true
          end
      }
      false
  end

  def epom_fname
    ".clide/epom.xml"
  end

  private :epom_fname, :init_dependencies, :has_parent?
end
#}}}

#{{{
def load_effective_pom(conf = ClideConfig.instance)
    epomfname = conf[:effective_pom]

    unless epomfname.exist?
        `(cd #{conf[:project_root]}; mvn help:effective-pom -Doutput=#{epomfname})`
    end

    POM.new epomfname
end
#}}}

conf = ClideConfig.instance
epom = load_effective_pom
epom.poms_have_been_updated?

conf[:dependencies].open('w+') { |f|
    f.puts epom.dependencies.to_yaml
}
