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
        src_md5s = Psych.load_file @clide.conf[:source_md5s]
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

module ProjectFunctions
    def find_sources(dir, glob) 
        Pathname::glob(dir + glob).collect { |src| SourceFile.new src }
    end
end

#{{{
class ModuleProject
    include ProjectFunctions
    attr_reader :name, :src_dirs, :sources, :pom_src

    def initialize(name, modpom, namespaces, clide = nil)
        @namespaces = namespaces
        @name       = name
        @pom_src    = SourceFile.new @clide.conf[:project_root] + name + "pom.xml"

        @src_dirs = {
            :main => Pathname.new(modpom.xpath("//xmlns:project[xmlns:artifactId = \"#{@name}\"]/xmlns:build/xmlns:sourceDirectory/text()", @namespaces).text),
            :test => Pathname.new(modpom.xpath("//xmlns:project[xmlns:artifactId = \"#{@name}\"]/xmlns:build/xmlns:testSourceDirectory/text()", @namespaces).text)
        }

        src_glob = "**/*.java"
        @sources = {
            :main => find_sources(@src_dirs[:main], src_glob),
            :test => find_sources(@src_dirs[:test], src_glob),
        }
    end
end
#}}}

##
# Object to represent all useful information from a maven pom.
#{{{
class Project
    include ProjectFunctions

    attr_accessor :group_id, :project_id, :version, :namespaces, :dependencies
    attr_accessor :modules, :sources, :root_pom_src

    def initialize(fname, clide = nil)
      @clide = clide
      return unless fname.exist?
      @module_poms = []

      @epom_fname   = fname
      @project_root = @clide.conf[:project_root]
      @root_pom_src = SourceFile.new(@project_root + "pom.xml")

      @epom_xml     = Nokogiri::XML(File.open(@epom_fname, 'r'))
      @namespaces   = @epom_xml.namespaces
      @namespaces   = { 'xmlns' => 'http://maven.apache.org/POM/4.0.0' } if @namespaces.empty?
      @modules      = {}
      @epom_xml.xpath("//xmlns:modules/xmlns:module/text()", @namespaces).each { |mname|
        modsym = artifactId_to_key mname.text
        @modules[modsym] = ModuleProject.new(mname.text, @epom_xml.xpath("//xmlns:project[xmlns:artifactId = \"#{mname}\"]", @namespaces), @namespaces, @clide)
      }
      @dependencies = init_dependencies

      @src_dirs = {
        :main => Pathname.new(@epom_xml.xpath("//xmlns:project[xmlns:artifactId = \"#{@name}\"]/xmlns:build/xmlns:sourceDirectory/text()", @namespaces).text),
        :test => Pathname.new(@epom_xml.xpath("//xmlns:project[xmlns:artifactId = \"#{@name}\"]/xmlns:build/xmlns:testSourceDirectory/text()", @namespaces).text)
      }

      # find the sources for just the project root
      @sources = {
        main: find_sources(@src_dirs[:main], '**/*.java'),
        test: find_sources(@src_dirs[:test], '**/*.java'),
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
        parent = @epom_xml.xpath "//xmlns:project[xmlns:modules]", @namespaces
        projects = @epom_xml.xpath "//xmlns:project/xmlns:modules/xmlns:module/text()", @namespaces

        @dependencies = {}
        @dependencies[:all] = {}

        projects.each { |prj|
            project_name = artifactId_to_key prj.text
            @dependencies[project_name] = Set.new

            prj.xpath("//xmlns:dependencies/xmlns:dependency", prj.namespaces).each { |dep|
                dependency = Dependency.new dep
                @dependencies[:all][dependency.coordinate] = dependency
                @dependencies[project_name] << dependency.coordinate
            }
        }

        @clide.conf[:dependencies][:file].open('w+') { |file|
            file.write Psych.dump @dependencies
        }

        @dependencies
    end

    ##
    # A parent project is one which has 1 or more modules defined in the pom
    def is_parent?
        !@epom_xml.modules.empty?
    end

    def get_pom_md5s
        md5s = [ @root_pom_src.to_md5 ]
        @modules.each { |k,module_pom|
            md5s << module_pom.pom_src.to_md5
        }
        md5s
    end

    def dump_source_md5s
        @clide.conf[:source_md5s].open("w+") { |srcmd5s|
            @sources.each { |type, srcfiles|
                srcfiles.each { |f| 
                    srcmd5s.puts f.to_md5 
                }
            } 
        }
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

    private :init_dependencies
end
#}}}

##
# Lazy load the effective pom.  We only want to parse the effective pom on initializing or updating a clide project, or
# when the pom's have been modified, and we want to guarantee to do this only once per invocation.
#{{{
def load_effective_pom(clide, force = false)
    return unless clide.poms_have_been_updated?
    epomfname = clide.conf[:effective_pom]

    unless epomfname.exist?
        `(cd #{clide.conf[:project_root]}; mvn help:effective-pom -Doutput=#{epomfname})`
    end

    Project.new epomfname
end
#}}}
