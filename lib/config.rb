#!/usr/bin/env ruby
# vim: fdm=marker ts=2 sw=2
# author:     Michael Brailsford
# created:    2015-08-23 23:22:09 -0500
# contents:   A module for dealing with clide configuration

require 'parseconfig'
require 'singleton'
require 'pathname'

require_relative 'utilities'

#{{{
class ClideConfig
    include Singleton

    attr_accessor :params, :project_root

    ##
    # Read the clide configuration file.  If one does not exist, an attempt will be made to find the project root
    # directory in the current working directory or its parent.
    #{{{
    def initialize
        #@params          = (File.exists? user_cliderc) ? ParseConfig.new(user_cliderc).params : {}
        # Bare minimum configuration that clide requires
        @params = {user_clide_config: Pathname.new(ENV['USER_CLIDERC'] || "#{ENV['HOME']}/.cliderc")}


        clide_config_dir = Pathname.new(@params['config.dir']      || ENV['CLIDE_CONFIG_DIR'] || ".clide")
        cliderc          = Pathname.new(@params['config.filename'] || ENV['CLIDERC']          || "#{clide_config_dir}/.cliderc")

        @project_root = ClideConfig::find_project_root_quick_and_dirty
        @params = {}

        projectrc = [@project_root, cliderc].join '/'
        if File.exists? projectrc
            conf = ParseConfig.new(projectrc)
            @params = conf.params
        else
            @params[:clide_conf_dir]          = clide_config_dir
            @params[:clide_config]            = cliderc
            @params[:pom_md5]                 = ENV['CLIDE_POM_MD5']           || "#{clide_config_dir}/pom.hsh"
            @params[:effective_pom]           = ENV['CLIDE_EFFECTIVE_POM']     || "#{clide_config_dir}/epom.xml"
            @params[:clide_maven_output_file] = ENV['CLIDE_MAVEN_OUTPUT_FILE'] || "#{clide_config_dir}/maven.out"

            # The following are planned, but are not used
            #@params[:classpath_file]          = ENV['CLIDE_CLASSPATH_FILE']    || "#{clide_config_dir}/classpath.txt"
            #@params[:javafiles]               = ENV['CLIDE_JAVAFILES']         || "#{clide_config_dir}/java.src"
            #@params[:testjavafiles]           = ENV['CLIDE_TESTJAVAFILES']     || "#{clide_config_dir}/java.test.src"
            #@params[:clide_build_order]       = ENV['CLIDE_BUILD_ORDER']       || "#{clide_config_dir}/build.order"
            #@params[:clide_compile_commands]  = ENV['CLIDE_COMPILE_COMMANDS']  || "#{clide_config_dir}/compile.sh"
            #@params[:clide_compiler_output]   = ENV['CLIDE_COMPILER_OUTPUT']   || "#{clide_config_dir}/compiler.output"

            Dir.mkdir @params[:clide_conf_dir] unless Dir.exist? @params[:clide_conf_dir]
            File.open(@params[:clide_config], 'w+') { |rc|
                conf = ParseConfig.new(rc)
                @params.each { |k,v|
                    conf.add k, v
                }
                conf.write rc
            }
        end
    end
    #}}}

    #{{{
    def [](key)
        @params[key]
    end
    #}}}

    def ClideConfig.find_project_root_quick_and_dirty(dir = Pathname::pwd)
        candidate = search_up_for 'pom.xml', {start_dir: dir}

        return dir if candidate.nil? and File.exists? 'pom.xml'
        raise "dammit" if candidate.nil?  # this implies ../pom.xml doesn't exist

        return File.dirname dir if !candidate.nil? && File.exists? "#{File.dirname(dir)}/pom.xml"
        raise "this *is* quick and dirty"
    end
end
#}}}

