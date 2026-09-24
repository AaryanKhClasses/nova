module Nova
    module Expander
        class Globber
            def expand(pattern : String) : Array(String)
                matches = Dir.glob(pattern)
                matches.empty? ? [pattern] : matches
            end
        end
    end
end
