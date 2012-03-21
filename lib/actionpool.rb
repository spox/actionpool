require 'rubygems'
begin
  require 'fastthread'
rescue LoadError
  # we don't care if it's available
  # just load it if it's around
end
require 'splib'
Splib.load :Array, :Monitor
require 'actionpool/Pool'