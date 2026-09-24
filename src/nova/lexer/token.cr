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
                @value.empty? ? @type.to_s : "#{@type}(#{@value})"
            end
        end
    end
end
