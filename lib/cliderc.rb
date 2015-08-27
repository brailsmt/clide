#!/usr/bin/env ruby
# author:     Michael Brailsford
# created:    2015-08-23 23:22:09 -0500
# contents:   

require 'parseconfig'

CLIDE_RC_DIRNAME = ENV['CLIDE_RC_DIRNAME'] || ".clide"

class ClideConfig
    attr_accessor :params

    def initialize(opts, project_root=nil)
        @params = {}

        conf_dir = "#{project_root}/#{CLIDE_RC_DIRNAME}"
        rcfile   = "#{conf_dir}/cliderc"
        if File.exists? rcfile
            conf = ParseConfig.new("#{@pom.project_root}/#{CLIDE_CONFIG}")
            @params = conf.params
        else
            @params[:clide_conf_dir]          = conf_dir
            @params[:clide_config]            = rcfile
            @params[:pom_md5]                 = "#{conf_dir}/pom.hsh"
            @params[:effective_pom]           = "#{conf_dir}/epom.xml"
            @params[:classpath_file]          = "#{conf_dir}/classpath.txt"
            @params[:javafiles]               = "#{conf_dir}/java.src"
            @params[:testjavafiles]           = "#{conf_dir}/java.test.src"
            @params[:clide_maven_output_file] = "#{conf_dir}/maven.out"
            @params[:clide_build_order]       = "#{conf_dir}/build.order"
            @params[:clide_compile_commands]  = "#{conf_dir}/compile.sh"
            @params[:clide_compiler_output]   = "#{conf_dir}/compiler.output"
        end
    end

    def save
        Dir.mkdir @params[:clide_conf_dir] unless Dir.exist? @params[:clide_conf_dir]
        File.open(@params[:clide_config], 'w+') { |rc|
            conf = ParseConfig.new(rc)
            @params.each { |k,v|
                conf.add k, v
            }
            conf.write rc
        }
    end

#    def search_upwards_for_file(filename)
#        file = File.absolute_path filename
#        until File.exist? filename
#            break if cwd == home
#            cwd = File.dirname cwd
#            search_dirs << cwd
#        end
#    end

    def ClideConfig.find_project_root
        cwd = File.absolute_path ENV['PWD']
        home = File.absolute_path Dir.home
        search_dirs = [cwd]
        project_root = nil

        until Dir.exist? "#{cwd}/#{CLIDE_RC_DIRNAME}" 
            break if cwd == home
            cwd = File.dirname cwd
            search_dirs << cwd
        end
        puts cwd

        unless Dir.exists? "#{cwd}/#{CLIDE_RC_DIRNAME}" 
            #$stderr.puts "!! No project configuration found in #{ENV['PWD']} !!"
            #$stderr.puts "Searched the following directories:"
            search_dirs.each { |dir|
                if Dir.exist?("#{dir}/#{CLIDE_RC_DIRNAME}") && File.exists?("#{dir}/pom.xml")
                    project_root = dir
                    break
                end
            }
            puts "No clide configuration found!"
            puts "Has 'clide init' been run yet?"
            raise "No clide configuration found"
        end
        project_root
    end
end
