begin
    require 'fastthread'
rescue LoadError
    # we don't care if it's available
    # just load it if it's around
end
require 'actionpool/Pool'