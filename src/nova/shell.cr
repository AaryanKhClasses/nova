require "./executor"
require "./builtins"

module Nova
    class Shell
        PROMPT = "nova> "

        def initialize
            @executor = Executor.new
        end

        def run
            puts "Nova Shell #{Nova::VERSION}"
            puts "Type 'exit' to quit."
            puts

            loop do
                print PROMPT
                input = gets
                break if input.nil?

                input = input.chomp
                next if input.empty?

                parts = input.split
                command = parts[0]
                args = parts[1..]

                next if Builtins.execute(command, args)
                @executor.execute(input)
            end
            puts
        end
    end
end
