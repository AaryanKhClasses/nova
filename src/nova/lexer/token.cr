require "./word_part"

module Nova
    module Lexer
        enum TokenType
            Word
            Pipe
            RedirectInput
            RedirectOutput
            RedirectAppend
            RedirectError
            Ampersand
        end

        struct Token
            getter type
            getter value
            getter parts

            def initialize(
                @type : TokenType,
                @value : String = "",
                @parts : Array(WordPart) = [] of WordPart
            )
            end

            def to_s
                if @value.empty?
                    @type.to_s
                else
                    "#{@type}(#{@value})"
                end
            end
        end
    end
end
