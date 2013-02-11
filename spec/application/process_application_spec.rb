#!/usr/bin/env rspec

require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../', 'application', 'process.rb')

module MCollective
  class Application
    describe Process do
      before do
        application_file = File.join(File.dirname(__FILE__), '../../', 'application', 'process.rb')
        @app = MCollective::Test::ApplicationTest.new("process", :application_file => application_file).plugin
      end

      describe '#application_description' do
        it 'should have a description' do
          @app.should have_a_description
        end
      end

      describe '#handle_message' do
        it 'should perform the correct action with the correct string for a code' do
          @app.expects(:print).with('Please provide an action')
          @app.expects(:print).with("'rspec' specified as process field. Valid options are PID, USER")
          @app.expects(:print).with("Invalid action. Valid action is 'list'")

          @app.handle_message(:print, 1)
          @app.handle_message(:print, 2, 'rspec', 'PID, USER')
          @app.handle_message(:print, 3)
        end
      end

      describe '#post_option_parser' do
        before do
          ARGV << 'list'
        end

        it 'should fail if an action was not specified' do
          ARGV.shift
          expect{
            @app.post_option_parser({})
          }.to raise_error
        end

        it 'should fail on an invalid action' do
          ARGV.shift
          ARGV << 'rspec'

          expect{
            @app.post_option_parser({})
          }.to raise_error
        end

        it 'should set fields from the cli' do
          config = {:fields => ['pid', 'user']}
          @app.post_option_parser(config)
          config[:fields].should == ['PID', 'USER']
        end

        it 'should set fields from pluginconf' do
          config = {}
          plugin_config = mock
          plugin_config.stubs(:pluginconf).returns({'process.fields' => 'pid, user, state'})
          Config.stubs(:instance).returns(plugin_config)
          @app.post_option_parser(config)
          config[:fields].should == ['PID', 'USER', 'STATE']
        end

        it 'should set the default fields' do
          config = {}
          plugin_config = mock
          plugin_config.stubs(:pluginconf).returns({})
          Config.stubs(:instance).returns(plugin_config)
          @app.post_option_parser(config)
          config[:fields].should == ['PID', 'USER', 'VSZ', 'COMMAND']
        end

        it 'should set the value of just_zombies to a TrueClass or FalseClass' do
          config = {:fields => []}
          @app.post_option_parser(config)
          config[:just_zombies].should == false

          ARGV << 'list'

          config[:just_zombies] = 'true'
          @app.post_option_parser(config)
          config[:just_zombies].should == true
        end

        it 'should set the pattern' do
          config = {:fields => []}
          ARGV << 'rspec'

          @app.post_option_parser(config)
          config[:pattern].should == 'rspec'
        end
      end

      describe '#validate_configuration' do
        it 'should validate valid fields' do
          config = {:fields => ['PID', 'USER', 'VSZ', 'COMMAND', 'TTY', 'RSS', 'STATE']}
          @app.validate_configuration(config)
        end

        it 'should fail on a invalid field name' do
          config = {:fields => ['rspec']}
          expect{
            @app.validate_configuration(config)
          }.to raise_error
        end
      end

      describe '#fields' do
        it 'should return an array of values corresponding to the supplied fields' do
          field_names = ['PID', 'USER', 'VSZ', 'COMMAND', 'TTY', 'RSS', 'STATE']
          process = {:pid      => 500,
                     :username => 'rspec',
                     :vsize    => 100,
                     :cmdline  => 'rspec',
                     :tty_nr   => 1,
                     :rss      => 1,
                     :state    => 'Z'
                    }
          Fixnum.any_instance.stubs(:bytes_to_human).returns('100 B')

          result = @app.fields(field_names, process)
          result.should == [500, 'rspec', '100 B', '[rspec]', 1, '100 B', 'Z']
        end
      end

      describe '#main' do
        let(:client) { mock }

        let(:process) do
          [{:pid      => 500,
           :username => 'rspec',
           :vsize    => 100,
           :cmdline  => 'rspec',
           :tty_nr   => 1,
           :rss      => 1,
           :state    => 'Z'
          }]
        end

        let(:resultset) do
          [{:statuscode => 0,
           :data => {:pslist => process},
           :sender => 'rspec',
           :statusmsg => 'error'
          }]
        end

        before do
          @app.configuration[:silent] = false
          @app.configuration[:pattern] = '.'
          @app.configuration[:fields] = ['PID', 'USER', 'COMMAND']
          @app.configuration[:just_zombies] = false
          @app.configuration[:action] = 'list'
          Fixnum.any_instance.stubs(:bytes_to_human).returns('100 B')
          @app.expects(:printrpcstats)
          @app.expects(:halt)

          PluginManager.stubs(:loadclass)
          @app.stubs(:rpcclient).with('process').returns(client)
          client.expects(:send).returns(resultset)
          client.stubs(:stats)
        end

        it 'should only print the summary if the silent flag is set' do
          @app.configuration[:silent] = true
          @app.main
        end

        it 'should print the correct fields with values' do
          @app.configuration[:silent] = false
          @app.expects(:puts).with('     500     rspec     [rspec]')
          @app.main
        end

        it 'should print the status message on failure' do
          resultset[0][:statuscode] = 1
          @app.expects(:puts).with('   rspec                    error')
          @app.main
        end
      end
    end
  end
end
