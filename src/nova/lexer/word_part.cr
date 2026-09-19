module Nova
    module Lexer
        enum QuoteType
            None
            Single
            Double
        end

        struct WordPart
            getter value
            getter quote

            def initialize(@value : String, @quote : QuoteType)
            end
        end
    end
end
