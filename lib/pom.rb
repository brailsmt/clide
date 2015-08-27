#!/usr/bin/env ruby
# author:     Michael Brailsford
# created:    2015-08-23 06:09:24 -0500
# contents:   Parse a pom.xml and extract useful information

require 'nokogiri'
require 'parseconfig'
require 'pp'

class POM
    attr_accessor :raw_pom, :deps, :classpath, :props, :pom
    attr_accessor :group_id, :project_id, :version
    attr_accessor :parent_gid, :parent_pid, :parent_version
    attr_accessor :project_root, :filename

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
        @project_root = File.dirname(File.absolute_path(fname))
        @filename = fname
        @pom = Nokogiri::XML(File.open(fname, 'r'))
    end

    def has_parent?
        puts @pom.namespaces
        @pom.xpath "/projects/project"
        parent = @pom.xpath "//xmlns:parent", @pom.namespaces
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
        Dir.mkdir ".clide" unless Dir.exist? ".clide"

        `mvn help:effective-pom -Doutput=#{epom_fname}`
    end

    def get_dependencies
        #build_effective_pom unless File.exists? epom_fname

        #pom = Nokogiri::XML(File.open('pom.xml', 'r'))
        deps_nodeset = @pom.xpath "/xmlns:project/xmlns:dependencies/xmlns:dependency", @pom.namespaces #/xmlns:dependency", @pom.namespaces
        pp deps_nodeset
#        deps_nodeset.each { |dep|
#            group = dep.xpath
#            project = dep.xpath
#            version = dep.xpath
#        }
        deps_nodeset
    end

    def load_props
    end
end
