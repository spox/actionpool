require 'test/unit'
require "#{File.dirname(__FILE__)}/../lib/actionpool.rb"

Dir.new("#{File.dirname(__FILE__)}/cases").each{|f|
    require "#{File.dirname(__FILE__)}/cases/#{f}" if f[-2..f.size] == 'rb'
}