require "../parser/word"
require "./environment"

module Nova
    module Expander
        class Expander
            getter environ,ment

            def initialize(@environment : Environment)
            end

            def expand_word(word : Parser::Word) : String
                String.build do |str|
                    word.parts.each do |part|
                        case part
                        when Parser::LiteralPart
                            expand_literal(part.value, str)
                        when Parser::SingleQuotedPart
                            str << part.value
                        when Parser::DoubleQuotedPart
                            expand_double_quoted(part.value, str)
                        end
                    end
                end
            end

            private def expand_literal(value : String, str : String::Builder)
                str << value
            end

            private def expand_double_quoted(value : String, str : String::Builder)
                str << value
            end
        end
    end
end
