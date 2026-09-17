require "./executor"
require "./builtins"
require "./lexer/lexer"
require "./parser/parser"

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

                begin
                    lexer = Lexer::Lexer.new(input)
                    tokens = lexer.tokenize
                    parser = Parser::Parser.new(tokens)
                    program = parser.parse
                    @executor.execute(program)
                rescue ex : Lexer::LexerError
                    STDERR.puts "Lexer error: #{ex.message}"
                rescue ex : Parser::ParserError
                    STDERR.puts "Parser error: #{ex.message}"
                rescue ex
                    STDERR.puts "Error: #{ex.message}"
                end
            end
            puts
        end
    end
end
