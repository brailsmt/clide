#!/usr/bin/env ruby
# vim: fdm=marker

require 'optparse'
require 'pp'
require 'psych'

require_relative "../config.rb"
require_relative "../plugin.rb"

module ClasspathPlugins
    class GetClasspath < Plugin
        def initialize(conf)
            @conf = conf
        end

        #{{{
        def help
            "print classpath in a format suitable for -cp option to javac"
        end
        #}}}

        #{{{
        def name
            "classpath"
        end
        #}}}

        #{{{
        def load_classpaths
            conf = ClideConfig.instance
            if not conf[:classpath][:file].exist?
                STDERR.puts "Could not load classpath information!"
                return nil
            end
            Psych.load_file conf[:classpath][:file]
        end
        #}}}

        #{{{
        def run(clide, module_names = nil)
            if module_names.nil? or module_names.empty?
              modname = Pathname.new(Dir.pwd).basename.to_s
            else
              modname = module_names.first
            end
            classpaths = load_classpaths

            cp = classpaths[clide.to_module_key modname].to_a.join ':'
            puts cp
            cp
        end
        #}}}

        def commands
            ["get"]
        end
    end

    @@config = nil
    @@clide = nil

    def register(clide)
        #puts "Loading ClasspathPlugins..."
        clide.register_plugin GetClasspath
    end
    module_function :register
end
