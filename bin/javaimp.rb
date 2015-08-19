#!/usr/bin/env ruby

require 'nokogiri'
require 'pp'

def classToJavaImpData(cls, trimNumDirs = 1)
    imp_data = []
    cls.each { |cname|
        cname.sub!(/\.class$/,"")
        info      = cname.split(/\//)
        info.shift(trimNumDirs)

        classname = info.pop
        package   = info.join(".");
        imp_data << "#{classname}\t#{package}"
    }
    imp_data
end

def getClasslistFromJars(jars)
    classes = []
    puts "Generating class list from:"
    jars.each { |jar|
        puts "  #{jar}"
        classes << `jar tf '#{jar}' 2> /dev/null`.split.select{|i| i =~ /.class$/}
    }

    return classes.flatten.sort.uniq
end

def getBuildDependenciesFromMaven(poms)
    jars = []
    poms.each { |pom|
        classpath = ""
        puts pom
        next

        puts "Processing #{pom}..."
        cpath=`(cd #{File.dirname pom}; mvn dependency:build-classpath) 2> /dev/null`
        readClasspath = false
        cpath.each_line { |line|
            if not readClasspath
                if line =~ /^\[INFO\] Dependencies classpath:.*/
                    readClasspath = true
                end
                next
            else
                break if line =~ /^\[INFO\]/
            end
            pp classpath
            classpath = line
        }
        jars << classpath.split(/;/);
    }

    jars = jars.flatten.sort.uniq

    classes = getClasslistFromJars jars

    return classToJavaImpData classes
end

def generateJavaImpDataFromTarget
    ary = []
    if File.exists?("target")
        Dir["target/*classes/**/*.class"].each { |cls|
            ary << classToJavaImpData(cls, 2)
        }
    end

    return ary
end

def fixupClasses(classes)
    rv = []

    classes.each {|c|
        next if c =~ /package-info/
        next if c !~ /^[0-9A-Z]/

        if c =~ /\$/

            info = c.split(/\t/)

            cls = info[0].split(/\$/)
            rv << "#{cls[0]}\t#{info[1]}"

            if cls[1] !~ /^\d+$/ and cls[1] !~ /^\s*$/
                rv << "#{cls[1]}\t#{info[1]}.#{cls[0]}"
            end
        else
            rv << c
        end
    }

    return rv.sort.uniq
end

def currentJavaImps(filename)
    # Load current JavaImp file
    imps = {}
    File.open(filename) { |file|
        file.each { |line|
            (name, className) = line.split(/\s+/)
            imps[name] = className
        }
    }
end

def is_parent?(doc)
    modules = doc.xpath "//xmlns:modules", doc.namespaces
    return false if modules.empty?
    true
end

class ParentPom
    attr_accessor :path, :xml
    def initialize(path, xml)
        @path = path
        @xml = xml
    end
end

def get_parent_pom(pom)
    raise "No pom found!" if File.absolute_path(pom) =~ /^#{ENV['HOME']}\/pom.xml$/
    doc = ParentPom.new(pom, Nokogiri::XML(File.open(pom)))
    return doc if is_parent? doc.xml

    get_parent_pom "../#{pom}"
end

def get_modules(doc)
    xml = doc.xml
    xml.xpath "//xmlns:modules/xmlns:module/text()", xml.namespaces
end

def main
    raise "No pom.xml in the current directory!" unless File.exists? "pom.xml"
    pom = get_parent_pom "pom.xml"
    modules = get_modules pom
    modules.each { |node|
        puts node.text
    }

    parent_dir = File.dirname pom.path
    classes = []
    #classes << generateJavaImpDataFromTarget
    #classes.flatten!
    #pp classes

    #puts fixupClasses(classes)
end

main
