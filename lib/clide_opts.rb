#!/usr/bin/env ruby

def get_clide_options
    options={}
    option_parser = OptionParser.new do |opts|
        opts.banner = "Usage:  clide [options] command [command options]"
        opts.on('-h', '--help', 'Display this help') {
            puts opts
            exit
        }
    end

    option_parser.parse!
    options
end
