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
        clide_conf_dir = Pathname.new(".clide")
        cliderc        = ".cliderc"

        @project_root = ClideConfig.find_project_root_quick_and_dirty.realpath
        @params = {}

        projectrc = @project_root + cliderc
        if projectrc.exist? 
            conf = ParseConfig.new(projectrc)
            conf.params.each { |k,v|
                @params[k.to_sym] = Pathname.new v
            }
        else
            clide_conf_dir = (@project_root + clide_conf_dir).realdirpath

            @params[:project_root]   = @project_root
            @params[:clide_conf_dir] = clide_conf_dir
            @params[:cliderc]        = projectrc.realdirpath

            Dir.mkdir clide_conf_dir unless clide_conf_dir.exist?
            @params[:pom_md5]           = Pathname.new(ENV['CLIDE_POM_MD5']           || clide_conf_dir + "pom.md5").realdirpath
            @params[:effective_pom]     = Pathname.new(ENV['CLIDE_EFFECTIVE_POM']     || clide_conf_dir + "epom.xml").realdirpath
            @params[:maven_output_file] = Pathname.new(ENV['CLIDE_MAVEN_OUTPUT_FILE'] || clide_conf_dir + "maven.out").realdirpath
            @params[:classpath_file]    = Pathname.new(ENV['CLIDE_CLASSPATH_FILE']    || clide_conf_dir + "classpath.txt").realdirpath
            @params[:javafiles]         = Pathname.new(ENV['CLIDE_JAVAFILES']         || clide_conf_dir + "java.src").realdirpath
            @params[:testjavafiles]     = Pathname.new(ENV['CLIDE_TESTJAVAFILES']     || clide_conf_dir + "java.test.src").realdirpath
            @params[:build_order]       = Pathname.new(ENV['CLIDE_BUILD_ORDER']       || clide_conf_dir + "build.order").realdirpath
            @params[:compile_commands]  = Pathname.new(ENV['CLIDE_COMPILE_COMMANDS']  || clide_conf_dir + "compile.sh").realdirpath
            @params[:compiler_output]   = Pathname.new(ENV['CLIDE_COMPILER_OUTPUT']   || clide_conf_dir + "compiler.output").realdirpath
            @params[:dependencies]      = Pathname.new(ENV['CLIDE_DEPENDENCIES']      || clide_conf_dir + "dependencies.yaml").realdirpath

            File.open(@params[:cliderc], 'w+') { |rc|
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
      pomfname = 'pom.xml'
      candidates = search_up_for pomfname, {start_dir: dir}

      raise "#{pomfname} count not be found!" if candidates.nil? || candidates.empty?
      candidates.last
    end
end
#}}}
