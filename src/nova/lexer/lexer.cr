require "./token"

module Nova
    module Lexer
        class LexerError < Exception
        end

        class Lexer
            def initialize(@input : String)
                @position = 0
            end

            def tokenize : Array(Token)
                tokens = [] of Token

                while @position < @input.size
                    skip_whitespace
                    break if @position >= @input.size
                    tokens << next_token
                end
                tokens
            end

            private def next_token : Token
                case current_char
                when '|'
                    advance
                    Token.new(TokenType::Pipe)
                when '<'
                    advance
                    Token.new(TokenType::RedirectInput)
                when '>'
                    advance
                    if current_char == '>'
                        advance
                        Token.new(TokenType::RedirectAppend)
                    else
                        Token.new(TokenType::RedirectOutput)
                    end
                when '&'
                    advance
                    Token.new(TokenType::Ampersand)
                else
                    read_word
                end
            end

            private def read_word : Token
                value = String.build do |str|
                    while @position < @input.size
                        char = current_char
                        break if char.whitespace?
                        break if "|<>-&".includes?(char)

                        case char
                        when '"'
                            read_quoted_string(str, '"')
                        when '\''
                            read_quoted_string(str, '\'')
                        else
                            str << char
                            advance
                        end
                    end
                end
                Token.new(TokenType::Word, value)
            end

            private def read_quoted_string(str : String::Builder, quote : Char)
                advance
                while @position < @input.size
                    char = current_char
                    if char == quote
                        advance
                        return
                    end
                    str << char
                    advance
                end

                quote_name = quote == '"' ? "double" : "single"
                raise LexerError.new("Unterminated #{quote_name} quote")
            end

            private def skip_whitespace
                while @position < @input.size && current_char.whitespace?
                    advance
                end
            end

            private def current_char : Char
                @input[@position]
            end

            private def advance
                @position += 1
            end
        end
    end
end
