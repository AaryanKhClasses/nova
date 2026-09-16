require "../lexer/token"
require "./ast"

module Nova
    module Parser
        class ParserError < Exception
        end

        class Parser
            def initialize(@tokens : Array(Lexer::Token))
                @position = 0
            end

            def parse : Program
                program = Program.new
                pipeline = parse_pipeline
                program.add_pipeline(pipeline)
                raise ParserError.new("Unexpected token after pipeline: #{current_token.type}") if @position < @tokens.size
                program
            end

            private def parse_pipeline : Pipeline
                pipeline = Pipeline.new

                loop do
                    command = parse_command
                    pipeline.add_command(command)
                    break unless match?(Lexer::TokenType::Pipe)
                end

                pipeline.background = true if match?(Lexer::TokenType::Ampersand)
                pipeline
            end

            private def parse_command : Command
                command = Command.new
                raise ParserError.new("Expected command, but reached end of input") unless @position < @tokens.size

                while @position < @tokens.size
                    token = current_token
                    case token.type
                    when Lexer::TokenType::Word
                        command.add_word(token.value)
                        advance
                    when Lexer::TokenType::RedirectInput,
                         Lexer::TokenType::RedirectOutput,
                         Lexer::TokenType::RedirectAppend,
                         Lexer::TokenType::RedirectError
                        redirect = parse_redirects
                        command.add_redirect(redirect)
                    else
                        break
                    end
                end
                
                raise ParserError.new("Expected command, but got #{current_token.type}") if command.words.empty?
                command
            end

            private def parse_redirects : Redirect
                type = case current_token.type
                when Lexer::TokenType::RedirectInput
                    advance
                    RedirectType::Input
                when Lexer::TokenType::RedirectOutput
                    advance
                    RedirectType::Output
                when Lexer::TokenType::RedirectAppend
                    advance
                    RedirectType::Append
                when Lexer::TokenType::RedirectError
                    advance
                    RedirectType::Error
                else
                    raise ParserError.new("Expected redirect, but got #{current_token.type}")
                end

                target = expect(Lexer::TokenType::Word)
                Redirect.new(type, target.value)
            end

            private def current_token : Lexer::Token
                @tokens[@position]
            end

            private def advance
                @position += 1
            end

            private def match?(type : Lexer::TokenType) : Bool
                return false if @position >= @tokens.size
                if current_token.type == type
                    advance
                    true
                else
                    false
                end
            end

            private def check?(type : Lexer::TokenType) : Bool
                return false if @position >= @tokens.size
                current_token.type == type
            end

            private def expect(type : Lexer::TokenType) : Lexer::Token
                raise ParserError.new("Expected #{type}, but reached end of input") if @position >= @tokens.size

                token = current_token
                raise ParserError.new("Expected #{type}, but got #{token.type}") unless token.type == type

                advance
                token
            end
        end
    end
end
