#!/usr/bin/env rspec

require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../', 'agent', 'process.rb')

module MCollective
  module Agent
    describe Process do
      before do
        Process.stubs(:require).with('sys/proctable')
        agent_file = File.join(File.dirname(__FILE__), "../../", "agent", "process.rb")
        @agent = MCollective::Test::LocalAgentTest.new("process", :agent_file => agent_file).plugin
      end

      describe 'list_action' do
        it 'should pass the pattern input' do
          @agent.expects(:get_proc_list).with('rspec', false, false)
          @agent.call(:list, :pattern => 'rspec')
        end

        it 'should pass the just_zombies input' do
          @agent.expects(:get_proc_list).with('.', true, false)
          @agent.call(:list, :just_zombies => true)
        end

        it 'should get the process list' do
          @agent.expects(:get_proc_list).with('.', false, false).returns('rspec')
          result = @agent.call(:list)
          result.should be_successful
          result.should have_data_items({:pslist => 'rspec'})
        end
      end

      describe '#ps_to_hash' do
        let(:input) { {:uid => '500', :x1 => 'y1', :x2 => 'y2'} }
        let(:uid) { mock }

        before do
          @agent.stubs(:require).with('etc')
          Etc.expects(:getpwuid).with('500').returns(uid)
        end

        it 'should transform a ProcTable Object into a hash' do
          uid.expects(:name).returns('rspec')
          result = @agent.send(:ps_to_hash, input)
          result.should == {:username => 'rspec', :x1 => 'y1', :x2 => 'y2', :uid => '500'}
        end

        it 'should log if the username cannot be determined' do
          uid.expects(:name).raises('error')
          Log.expects(:debug).with('Could not get username for 500: error')
          result = @agent.send(:ps_to_hash, input)
          result.should == {:username => '500', :x1 => 'y1', :x2 => 'y2', :uid => '500'}
        end
      end

      describe '#get_uid' do
        let(:name) { mock }

        before do
          @agent.stubs(:require).with('etc')
          Etc.expects(:getpwnam).with('user1').returns(name)
        end

        it 'should transform username into uid' do
          name.expects(:uid).returns('500')
          result = @agent.send(:get_uid, 'user1')
          result.should == '500'
        end

        it 'should log and return false if uid cannot be determined' do
          name.expects(:uid).raises('error')
          Log.expects(:debug).with('Could not get uid for user: user1')
          result = @agent.send(:get_uid, 'user1')
          result.should be_false
        end
      end

      describe '#get_proc_list' do
        let(:input) { [{'cmdline' => 'rspec1', :state => 'S', 'uid' => 500}, {'cmdline' => 'rspec2', :state => 'Z', 'uid' => 501}] }
        module Sys; module ProcTable; end; end;

        it 'should return processes that match the supplied pattern' do
          Sys::ProcTable.stubs(:ps).returns(input)
          @agent.stubs(:ps_to_hash).with(input[0]).returns(input[0])
          result = @agent.send(:get_proc_list, 'rspec1', false, false)
          result.should == [{'cmdline' => 'rspec1', :state => 'S', 'uid' => 500}]
        end

        it 'should return only zombies if just_zombies input is supplied' do
          Sys::ProcTable.stubs(:ps).returns(input)
          @agent.stubs(:ps_to_hash).with(input[1]).returns(input[1])
          result = @agent.send(:get_proc_list, 'rspec2', true, false)
          result.should == [{'cmdline' => 'rspec2', :state => 'Z', 'uid' => 501}]
        end

        it 'should return only processes executed as supplied user' do
          Sys::ProcTable.stubs(:ps).returns(input)
          @agent.stubs(:get_uid).with('user1').returns(500)
          result = @agent.send(:get_proc_list, '.', false, 'user1')
          result.should == [{'cmdline' => 'rspec1', :state => 'S', 'uid' => 500}]
        end

        it 'should return only processes executed as supplied user' do
          Sys::ProcTable.stubs(:ps).returns(input)
          @agent.stubs(:get_uid).with('user2').returns(502)
          result = @agent.send(:get_proc_list, '.', false, 'user2')
          result.should == []
        end

      end
    end
  end
end
