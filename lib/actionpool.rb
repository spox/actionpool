begin
    require 'fastthread'
rescue LoadError
    # we don't care if it's available
    # just load it if it's around
end

# Here is a little bit of Hackery to make Array behave like
# it does in 1.9

if(Object::RUBY_VERSION < '1.9.0')
    class Array
        def fixed_flatten(level = -1)
            case
            when level < 0
                flatten
            when level == 0
                self
            when level > 0
                arr = []
                curr = self
                level.times do
                    curr.each do |elm|
                        if(elm.respond_to?(:to_ary))
                            elm.each{|e| arr << e }
                        else
                            arr << elm
                        end
                    end
                    curr = arr.dup
                end
            end
            arr
        end
    end
end
require 'actionpool/Pool'