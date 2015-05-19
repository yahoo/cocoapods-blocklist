#  Created by David Grandinetti 4/27/2015
#  Copyright (c) 2015 Yahoo, Inc.
#  Licensed under the terms of the MIT License. See LICENSE file in the project root.

require 'json'
require 'open-uri'

module Pod
  class Command
    class Blacklist < Command
      self.summary = 'Validate a project against a list of banned pods.'

      self.description = <<-DESC
        Validate a project against a list of banned pods. Requires a lockfile
        and a config file (JSON).
        
        example:
        $ pod blacklist --config blacklist.json
      DESC

      self.arguments = [
        CLAide::Argument.new('LOCKFILE', false),
      ]
      
      def self.options
        [
          ['--config=CONFIG', 'Config file or URL for the blacklist'],
          ['--warn', 'Only warn about use of banned pods'],
        ].concat(super)
      end

      def initialize(argv)
        @blacklist = argv.option('config')
        @warn = argv.flag?('warn') || false
        @lockfile_name = argv.shift_argument || "./Podfile.lock"
        super
      end

      def validate!
        super
        unless File.exists?(@lockfile_name)
          help! 'A lockfile and blacklist file are needed.'
        end
      end

      def run
        lockfile = Pod::Lockfile.from_file(Pathname.new(@lockfile_name))
        open(@blacklist) do |f|
          @blacklist_file = JSON.parse(f.read)
        end

        warned = false
        failed_pods = {}
        
        @blacklist_file['pods'].each do |pod|
          name = pod['name']
          if lockfile.pod_names.include? name
            version = Pod::Version.new(lockfile.version(name))
            if Pod::Requirement.create(pod['versions']).satisfied_by?(version)
              UI.puts "[!] Validation error: Use of #{name} #{version} for reason: #{pod['reason']}".yellow
              failed_pods[name] = version
              warned = true
            end
          end
        end
        if !warned
          UI.puts "#{@lockfile_name} passed blacklist validation".green
        else
          failed_pod_string = failed_pods.map { |name, version| "#{name} (#{version})"}.join(", ")
          unless @warn
            raise Informative.new("Failed blacklist validation due to use of #{failed_pod_string}")
          end
        end
      end
      
    end
  end
end
