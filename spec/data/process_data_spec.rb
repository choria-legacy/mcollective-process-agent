#!/usr/bin/ruby

require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../', 'data', 'process_data.rb')

module MCollective
  module Data
    describe Process_data do
      before do
        Process_data.stubs(:require)
        @data_file = File.join(File.dirname(__FILE__), '../../', 'data', 'process_data.rb')
        @data = MCollective::Test::DataTest.new("process_data", :data_file => @data_file).plugin
      end

      describe '#query' do
        module Sys; class ProcTable; end; end;

        it 'should return true if a process is running' do
          Sys::ProcTable.expects(:ps).returns([{'cmdline' => 'rspec'}])
          @data.lookup('rspec').should have_data_items({:exists => true})
        end

        it 'should return false if a process is not running' do
          Sys::ProcTable.expects(:ps).returns([{'cmdline' => 'rspec'}])
          @data.lookup('!rspec').should have_data_items({:exists => false})
        end
      end
    end
  end
end
