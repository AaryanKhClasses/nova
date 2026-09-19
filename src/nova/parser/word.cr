module Nova
    module Parser
        abstract class WordPart
        end

        class LiteralPart < WordPart
            getter value
            def initialize(@value : String)
            end
        end

        class SingleQuotedPart < WordPart
            getter value
            def initialize(@value : String)
            end
        end

        class DoubleQuotedPart < WordPart
            getter value
            def initialize(@value : String)
            end
        end

        class Word
            getter parts
            def initialize
                @parts = [] of WordPart
            end

            def add_part(part : WordPart)
                @parts << part
            end
        end
    end
end
