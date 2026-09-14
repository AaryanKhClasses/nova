module Nova
    class Shell
        PROMPT = "nova> "

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

                if input == "exit"
                    break
                end

                puts input
            end
        end
    end
end
