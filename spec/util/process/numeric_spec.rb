#!/usr/bin/ruby

require 'spec_helper'
require File.join(File.dirname(__FILE__), '../../../', 'util', 'process', 'numeric.rb')

class Numeric
  describe 'bytes_to_human' do
    it 'should return 0 if the value is a fraction' do
      0.4.bytes_to_human.should == '0 B'
    end

    it 'should return 0 if the value is negative' do
      -1.bytes_to_human.should == '0 B'
    end

    it 'should correctly convert bignums' do
      (1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024).bytes_to_human.should == '1073741824.000 TB'
    end

    it 'should cap the result at TB' do
      (1024 * 1024 * 1024 * 1024 * 1024).bytes_to_human.should == '1024.000 TB'
    end

    it 'should convert a value to the correct humand readable format' do
      50.bytes_to_human.should == '50.000 B'
      1024.bytes_to_human.should == '1.000 KB'
      (1024 * 1024).bytes_to_human.should == '1.000 MB'
      (1024 * 1024 * 1024).bytes_to_human.should == '1.000 GB'
      (1024 * 1024 * 1024 * 1024).bytes_to_human.should == '1.000 TB'
    end
  end
end
