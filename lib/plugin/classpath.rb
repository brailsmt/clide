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
        def -load_classpaths
            conf = ClideConfig.instance
            if conf[:classpath][:file].exist?
                conf[:classpath][:modules] = Psych.load_file conf[:classpath][:file]
            else
                generate_classpaths
            end
        end
        #}}}

        #{{{
        def run(clide, module_name)
            classpath = clide.get_classpath module_name

            cp = classpath.join ':'
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
        puts "Loading ClasspathPlugins..."
        clide.register_plugin GetClasspath
    end
    module_function :register
end
