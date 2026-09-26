module Nova
    module Expander
        alias CommandExecutor = Proc(String, IO, Int32)

        class Substituter
            def initialize(@executor : CommandExecutor)
            end

            def execute(command : String) : String
                output = IO::Memory.new
                @executor.call(command, output)
                output.to_s.chomp
            end
        end
    end
end
