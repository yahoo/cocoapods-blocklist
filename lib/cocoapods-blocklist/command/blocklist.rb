#  Created by David Grandinetti 4/27/2015
#  Copyright (c) 2015 Yahoo, Inc.
#  Licensed under the terms of the MIT License. See LICENSE file in the project root.

require 'json'
require 'open-uri'

module Pod
  class Command
    class Blocklist < Command
      self.summary = 'Validate a project against a list of blocked pods.'

      self.description = <<-DESC
        Validate a project against a list of blocked pods. Requires a lockfile
        and a config file (JSON).

        example:
        $ pod blocklist --config blocklist.json
      DESC

      self.arguments = [
        CLAide::Argument.new('LOCKFILE', false),
      ]

      def self.options
        [
          ['--config=CONFIG', 'Config file or URL for the blocklist'],
          ['--warn', 'Only warn about use of blocked pods'],
        ].concat(super)
      end

      def initialize(argv)
        @blocklist = argv.option('config')
        @warn = argv.flag?('warn')
        @lockfile_path = argv.shift_argument
        super
      end

      def validate!
        super

        @lockfile = @lockfile_path ? Lockfile.from_file(Pathname(@lockfile_path)) : config.lockfile
        help! 'A lockfile is needed.' unless lockfile
        help! 'A blocklist file is needed.' unless @blocklist
      end

      def run
        open(@blocklist) do |f|
          @blocklist_file = JSON.parse(f.read)
        end

        warned = false
        failed_pods = {}

        @blocklist_file['pods'].each do |pod|
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
          UI.puts "#{UI.path lockfile.defined_in_file.expand_path} passed blocklist validation".green
        else
          failed_pod_string = failed_pods.map { |name, version| "#{name} (#{version})"}.join(", ")
          unless @warn
            raise Informative.new("Failed blocklist validation due to use of #{failed_pod_string}")
          end
        end
      end

      private

      attr_reader :lockfile
    end
  end
end
