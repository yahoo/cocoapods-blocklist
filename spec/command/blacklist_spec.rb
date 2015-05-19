#  Created by David Grandinetti 4/27/2015
#  Copyright (c) 2015 Yahoo, Inc.
#  Licensed under the terms of the MIT License. See LICENSE file in the project root.

require File.expand_path('../../spec_helper', __FILE__)

GOOD_LOCKFILE = './spec/fixtures/GoodPodfile.lock'
BAD_LOCKFILE = './spec/fixtures/BadPodfile.lock'
DOUBLE_BAD_LOCKFILE = './spec/fixtures/DoubleBadPodfile.lock'
BLACKLIST_FILE = './spec/fixtures/blacklist.json'
BLACKLIST_URL = 'http://example.com/blacklist.json'

NON_EXIST_FILE = './spec/fixtures/doesnotexist'

module Pod
  describe Command::Blacklist do
    describe 'In general' do
      it 'registers itself' do
        Command.parse(%w{ blacklist }).should.be.instance_of Command::Blacklist
      end
      
      it 'defaults to show help' do
        lambda { run_command('blacklist') }.should.raise CLAide::Help
      end
    end
    
    it 'validates Podfile.lock exists if not passed in' do
      command = Command.parse(['blacklist', "--config=#{BLACKLIST_FILE}"])
      lambda { command.validate! }.should.raise CLAide::Help
    end

    it 'validates the lockfile exists if passed in' do
      command = Command.parse(['blacklist', NON_EXIST_FILE, "--config=#{BLACKLIST_FILE}"])
      lambda { command.validate! }.should.raise CLAide::Help
    end

    describe 'running with required args' do
      it 'allows valid pods with a local blacklist file' do
        command = Command.parse(['blacklist', GOOD_LOCKFILE, "--config=#{BLACKLIST_FILE}"])
        lambda {
          command.validate!
          command.run
        }.should.not.raise
      end

      it 'allows valid pods with a remote blacklist file' do
        WebMock::API.stub_request(:get, "http://example.com/blacklist.json").
          with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => File.read(BLACKLIST_FILE), :headers => {})
        
        command = Command.parse(['blacklist', GOOD_LOCKFILE, "--config=#{BLACKLIST_URL}"])
        lambda {
          command.validate!
          command.run
        }.should.not.raise
        UI.output.should.include "passed blacklist validation"
      end
      
      describe 'having blacklisted pods' do
        it 'disallows a banned pod' do
          command = Command.parse(['blacklist', BAD_LOCKFILE, "--config=#{BLACKLIST_FILE}"])
          exception = lambda {
            command.validate!
            command.run
          }.should.raise Informative
          exception.message.should.include "Failed blacklist validation due to use of BananaKit"
          UI.output.should.include "Vulnerable to code injection with malformed BQL queries"
        end
        
        it 'prints all banned pods' do
          command = Command.parse(['blacklist', DOUBLE_BAD_LOCKFILE, "--config=#{BLACKLIST_FILE}"])
          exception = lambda {
            command.validate!
            command.run
          }.should.raise Informative
          exception.message.should.include "Failed blacklist validation due to use of"
          exception.message.should.include "BananaKit (3.4.7)"
          exception.message.should.include "FooKit (1.2.2)"
          UI.output.should.include "FooKit 1.2.2 did not check passwords on Thursdays"
          UI.output.should.include "Vulnerable to code injection with malformed BQL queries"
        end
        
        it 'warns about banned pods when --warn is used' do
          command = Command.parse(['blacklist', DOUBLE_BAD_LOCKFILE, "--config=#{BLACKLIST_FILE}", "--warn"])
          exception = lambda {
            command.validate!
            command.run
          }.should.not.raise
          UI.output.should.include "FooKit 1.2.2 did not check passwords on Thursdays"
          UI.output.should.include "Vulnerable to code injection with malformed BQL queries"
        end
      end
    end
  end
end
