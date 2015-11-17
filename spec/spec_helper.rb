#  Created by David Grandinetti 4/27/2015
#  Copyright (c) 2015 Yahoo, Inc.
#  Licensed under the terms of the MIT License. See LICENSE file in the project root.

require 'pathname'
ROOT = Pathname.new(File.expand_path('../../', __FILE__))
$:.unshift((ROOT + 'lib').to_s)
$:.unshift((ROOT + 'spec').to_s)

require 'bundler/setup'
require 'bacon'
require 'pretty_bacon'
require 'cocoapods'

require 'webmock'
WebMock.disable_net_connect!

require 'cocoapods_plugin'

#-----------------------------------------------------------------------------#

module Pod

  # Disable the wrapping so the output is deterministic in the tests.
  #
  UI.disable_wrap = true

  # Redirects the messages to an internal store.
  #
  module UI
    @output = ''
    @warnings = ''

    class << self
      attr_accessor :output
      attr_accessor :warnings

      def puts(message = '')
        @output << "#{message}\n"
      end

      def warn(message = '', actions = [])
        @warnings << "#{message}\n"
      end

      def print(message)
        @output << message
      end
    end
  end
end

module SpecHelper
  module Command
    def argv(*argv)
      CLAide::ARGV.new(argv)
    end

    def command(*argv)
      argv << '--no-ansi'
      Pod::Command.parse(argv)
    end

    def run_command(*args)
      Pod::UI.output = ''
      # @todo Remove this once all cocoapods has
      # been converted to use the UI.puts
      config_silent = config.silent?
      config.silent = false
      cmd = command(*args)
      cmd.validate!
      cmd.run
      config.silent = config_silent
      Pod::UI.output
    end
  end
end

Bacon.summary_at_exit

module Bacon
  class Context
    include Pod::Config::Mixin
    # include SpecHelper::Fixture
    include SpecHelper::Command

    # def skip_xcodebuild?
    #   ENV['SKIP_XCODEBUILD']
    # end

    def temporary_directory
      SpecHelper.temporary_directory
    end
  end
end
