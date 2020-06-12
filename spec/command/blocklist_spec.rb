#  Created by David Grandinetti 4/27/2015
#  Copyright (c) 2015 Yahoo, Inc.
#  Licensed under the terms of the MIT License. See LICENSE file in the project root.

require File.expand_path('../../spec_helper', __FILE__)

GOOD_LOCKFILE = './spec/fixtures/GoodPodfile.lock'
BAD_LOCKFILE = './spec/fixtures/BadPodfile.lock'
DOUBLE_BAD_LOCKFILE = './spec/fixtures/DoubleBadPodfile.lock'
BLOCKLIST_FILE = './spec/fixtures/blocklist.json'
BLOCKLIST_URL = 'http://example.com/blocklist.json'

NON_EXIST_FILE = './spec/fixtures/doesnotexist'

module Pod
  describe Command::Blocklist do
    describe 'In general' do
      it 'registers itself' do
        Command.parse(%w{ blocklist }).should.be.instance_of Command::Blocklist
      end
      
      it 'defaults to show help' do
        lambda { run_command('blocklist') }.should.raise CLAide::Help
      end
    end
    
    it 'validates Podfile.lock exists if not passed in' do
      command = Command.parse(['blocklist', "--config=#{BLOCKLIST_FILE}"])
      lambda { command.validate! }.should.raise CLAide::Help
    end

    it 'validates the lockfile exists if passed in' do
      command = Command.parse(['blocklist', NON_EXIST_FILE, "--config=#{BLOCKLIST_FILE}"])
      lambda { command.validate! }.should.raise CLAide::Help
    end

    describe 'running with required args' do
      it 'allows valid pods with a local blocklist file' do
        command = Command.parse(['blocklist', GOOD_LOCKFILE, "--config=#{BLOCKLIST_FILE}"])
        lambda {
          command.validate!
          command.run
        }.should.not.raise
      end

      it 'allows valid pods with a remote blocklist file' do
        WebMock::API.stub_request(:get, "http://example.com/blocklist.json").
          with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => File.read(BLOCKLIST_FILE), :headers => {})
        
        command = Command.parse(['blocklist', GOOD_LOCKFILE, "--config=#{BLOCKLIST_URL}"])
        lambda {
          command.validate!
          command.run
        }.should.not.raise
        UI.output.should.include "passed blocklist validation"
      end
      
      describe 'having blocked pods' do
        it 'disallows a blocked pod' do
          command = Command.parse(['blocklist', BAD_LOCKFILE, "--config=#{BLOCKLIST_FILE}"])
          exception = lambda {
            command.validate!
            command.run
          }.should.raise Informative
          exception.message.should.include "Failed blocklist validation due to use of BananaKit"
          UI.output.should.include "Vulnerable to code injection with malformed BQL queries"
        end
        
        it 'prints all blocked pods' do
          command = Command.parse(['blocklist', DOUBLE_BAD_LOCKFILE, "--config=#{BLOCKLIST_FILE}"])
          exception = lambda {
            command.validate!
            command.run
          }.should.raise Informative
          exception.message.should.include "Failed blocklist validation due to use of"
          exception.message.should.include "BananaKit (3.4.7)"
          exception.message.should.include "FooKit (1.2.2)"
          UI.output.should.include "FooKit 1.2.2 did not check passwords on Thursdays"
          UI.output.should.include "Vulnerable to code injection with malformed BQL queries"
        end
        
        it 'warns about blocked pods when --warn is used' do
          command = Command.parse(['blocklist', DOUBLE_BAD_LOCKFILE, "--config=#{BLOCKLIST_FILE}", "--warn"])
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
