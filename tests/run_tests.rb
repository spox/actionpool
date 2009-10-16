require 'test/unit'
require 'actionpool'

Dir.new("#{File.dirname(__FILE__)}/cases").each{|f|
    require "#{File.dirname(__FILE__)}/cases/#{f}" if f[-2..f.size] == 'rb'
}
