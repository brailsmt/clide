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

DBG=Pathname.new('out.dbg.txt').open('w')
##
# Object to represent all useful information from a maven pom.
#{{{
class Project
  attr_accessor :key, :deps, :src_dirs, :sources

  def initialize(pom, namespaces = { 'xmlns' => 'http://maven.apache.org/POM/4.0.0' })
    @all_sources = Set.new
    @pom         = pom
    @namespaces  = namespaces
    @deps        = Set.new
    @src_dirs    = {}
    @sources     = {}

    @groupId    = @pom.xpath('xmlns:groupId/text()',    @namespaces).text.strip
    @artifactId = @pom.xpath('xmlns:artifactId/text()', @namespaces).text.strip
    @key       = "#{@groupId}:#{@artifactId}"

    @modules = nil
    @pom.xpath("//xmlns:project/xmlns:modules/xmlns:module/text()", @namespaces).each { |mname|
      @modules = [] if @modules.nil?
      @modules << "#{@groupId}:#{mname}"
    }
    init_dependencies
    init_sources
  end

  def artifactId_to_key(artifactId)
    artifactId.gsub(/-/, "_").to_sym
  end

  def key_to_artifactId(key)
    key.to_s.gsub(/_/, "-")
  end

  def init_dependencies
    @pom.xpath("xmlns:dependencies/xmlns:dependency", @namespaces).each { |dep|
      @deps << Dependency.new(dep)
    }
  end

  def init_sources
    @src_dirs = {
      :main => Pathname.new(@pom.xpath("xmlns:sourceDirectory/text()", @namespaces).text),
      :test => Pathname.new(@pom.xpath("xmlns:testSourceDirectory/text()", @namespaces).text)
    }

    @src_dirs.each { |type, src_dir|
      @sources[type] = find_sources(src_dir, '**/*.java')
    }
  end

  def get_pom_md5s
    md5s = [ @root_pom_src.to_md5 ]
    @modules.each { |k,module_pom|
      md5s << module_pom.pom_src.to_md5
    }
    md5s
  end

  def dump_source_md5s
#    @clide.conf[:source_md5s].open("w+") { |srcmd5s|
#      @sources.each { |type, srcfiles|
#        srcfiles.each { |f| 
#          srcmd5s.puts f.to_md5 
#        }
#      } 
#    }
  end

  def changed_sources
    @sources.each { |type,srclist|
      srclist.each { |src|
        puts src.filename if src.is_out_of_date?
      }
    }

    @modules.each { |modsym, modobj|
      modobj.sources.each { |type, srclist|
        srclist.each { |src|
          puts src.filename if src.is_out_of_date?
        }
      }
    }
  end

  def find_sources(dir, glob) 
    Pathname::glob(dir + glob).collect { |src|
      SourceFile.new src
    }
  end

  def classpath

  end

  private :init_dependencies
end
#}}}
