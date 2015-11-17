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
        @warn = argv.flag?('warn')
        @lockfile_path = argv.shift_argument
        super
      end

      def validate!
        super

        @lockfile = @lockfile_path ? Lockfile.from_file(Pathname(@lockfile_path)) : config.lockfile
        help! 'A lockfile is needed.' unless lockfile
        help! 'A blacklist file is needed.' unless @blacklist
      end

      def run
        open(@blacklist) do |f|
          @blacklist_file = JSON.parse(f.read)
        end

        warned = false
        failed_pods = {}

        @blacklist_file['pods'].each do |pod|
          name = pod['name']
          if lockfile.pod_names.include? name
            version = Version.new(lockfile.version(name))
            if Requirement.create(pod['versions']).satisfied_by?(version)
              UI.puts "[!] Validation error: Use of #{name} #{version} for reason: #{pod['reason']}".yellow
              failed_pods[name] = version
              warned = true
            end
          end
        end
        if !warned
          UI.puts "#{UI.path lockfile.defined_in_file.expand_path} passed blacklist validation".green
        else
          failed_pod_string = failed_pods.map { |name, version| "#{name} (#{version})"}.join(", ")
          unless @warn
            raise Informative.new("Failed blacklist validation due to use of #{failed_pod_string}")
          end
        end
      end

      private

      attr_reader :lockfile
    end
  end
end
