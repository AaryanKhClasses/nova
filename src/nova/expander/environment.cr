module Nova
    module Expander
        class Environment
            def initialize
                @variables = { } of String => String
            end

            def set(name : String, value : String)
                @variables[name] = value
            end

            def get(name : String) : String?
                @variables[name]?
            end

            def include?(name : String) : Bool
                @variables.has_key?(name)
            end
        end
    end
end
