#!/usr/bin/env rspec

require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../', 'aggregate', 'process_summary.rb')

module MCollective
  class Aggregate
    describe Process_summary do
      let(:aggregate) { Process_summary.new(:test, [], nil, :test_action) }
      let(:input) { [{:rss => 1, :vsize => 100}, {:rss => 2, :vsize => 200}] }


      before do
        PluginManager.stubs(:loadclass)
      end

      describe '#startup_hook' do
        it 'should load the Numeric monkey patch' do
          PluginManager.expects(:loadclass).with('MCollective::Util::Process::Numeric')
          aggregate
        end

        it 'should set type and value variables' do
          aggregate.result[:value].should == [0, 0, 0, 0]
          aggregate.result[:type].should == :numeric
        end
      end

      describe '#process_result' do
        it 'should not increment the host count if value is empty' do
          aggregate.process_result([], {})
          aggregate.result[:value].should == [0, 0, 0, 0]
        end

        it 'should increment the host, count, rss, vsize correctly' do
          aggregate.process_result(input, {})
          aggregate.result[:value].should == [1, 2, 3072, 300]
        end
      end

      describe '#summarize' do
        it 'should summarize the results correctly' do
          Fixnum.any_instance.expects(:bytes_to_human).twice
          aggregate.process_result(input, {})
          aggregate.summarize
        end
      end
    end
  end
end
