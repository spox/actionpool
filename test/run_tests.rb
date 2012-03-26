$LOAD_PATH.unshift(File.expand_path("#{__FILE__}/../../lib"))

require 'test/unit'
require 'actionpool'

Dir.glob(File.join(File.dirname(__FILE__), 'cases', '*.rb')).each do |file|
  require file
end
