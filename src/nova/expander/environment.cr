module Nova
    module Expander
        class Environment
            getter last_status

            def initialize
                @variables = { } of String => String
                @last_status = 0
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

            def set_last_status(status : Int32)
                @last_status = status
            end
        end
    end
end
