#!/usr/bin/env ruby
# author:     Michael Brailsford
# created:    2015-08-23 06:09:24 -0500
# contents:   Parse a pom.xml and extract useful information

require 'nokogiri'
require 'parseconfig'
require 'pp'

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

    ##
    # Find the parent pom, assuming the pom in the current directory is the parent and then searching up the directory tree
    # if that is not that case.
    #{{{
    def POM.find_parent_pom
        pom_dir = Dir.pwd
        until pom_dir == Dir.home
            break if File.exists? "#{pom_dir}/pom.xml"
            pom_dir = File.dirname pom_dir
        end
        pom = POM.new "#{pom_dir}/pom.xml"

        while pom.has_parent?
            if pom_dir == Dir.home
                pom = nil
                break
            end

            pom_dir = File.dirname pom_dir
            next unless File.exists? "#{pom_dir}/pom.xml"

            pom = POM.new "#{pom_dir}/pom.xml"
        end

#        if File.exists? "#{pom.project_root}/#{CLIDE_CONFIG}"
#            conf = ParseConfig.new("#{@pom.project_root}/#{CLIDE_CONFIG}")
#            ppom_fname = conf['parent.pom']
#            return POM.new ppom_fname unless ppom_fname == nil
#        else
#            Dir.mkdir CLIDE_CONF_DIR unless Dir.exist? CLIDE_CONF_DIR
#            File.open(CLIDE_CONFIG, 'w+') { |rcfile|
#                conf = ParseConfig.new(rcfile)
#                conf.add 'parent.pom', pom_fname
#                conf.write rcfile
#            }
#        end
        pom
    end
    #}}}

    def initialize(fname)
        @namespaces = { 'xmlns' => 'http://maven.apache.org/POM/4.0.0' }
        @filename = fname
        @project_root = File.dirname(File.absolute_path(@filename))
        @pom = Nokogiri::XML(File.open(@filename, 'r'))
        @dependencies = {}
    end

    def has_parent?
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
    
    def build_effective_pom
        return if File.exists? epom_fname

        Dir.mkdir ".clide" unless Dir.exist? ".clide"

        `mvn help:effective-pom -Doutput=#{epom_fname}`
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
