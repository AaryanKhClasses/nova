require "../parser/word"
require "./environment"

module Nova
    module Expander
        class Expander
            getter environment

            def initialize(@environment : Environment)
            end

            def expand_word(word : Parser::Word) : String
                String.build do |str|
                    word.parts.each do |part|
                        case part
                        when Parser::LiteralPart
                            expand_variables(part.value, str)
                        when Parser::SingleQuotedPart
                            str << part.value
                        when Parser::DoubleQuotedPart
                            expand_variables(part.value, str)
                        end
                    end
                end
            end

            def expand_string(value : String) : String
                String.build do |str|
                    expand_variables(value, str)
                end
            end

            private def expand_variables(value : String, str : String::Builder)
                position = 0
                while position < value.size
                    char = value[position]

                    if char == '$'
                        consumed = expand_variable(value, position, str)
                        if consumed > 0
                            position += consumed
                            next
                        end
                    end

                    str << char
                    position += 1
                end
            end
            
            private def expand_variable(value : String, position : Int32, str : String::Builder) : Int32
                next_position = position + 1
                return 0 if next_position >= value.size

                if value[next_position] == '?'
                    str << @environment.last_status.to_s
                    return 2
                end

                if value[next_position] == '{'
                    closing = value.index('}', next_position + 1)
                    return 0 if closing.nil?

                    name = value[(next_position + 1)...closing]
                    return 0 unless valid_variable_name?(name)
                    str << variable_value(name)
                    return closing - position + 1
                end

                name_start = next_position
                return 0 unless valid_variable_start?(value[name_start])
                name_end = name_start
                while name_end < value.size && valid_variable_char?(value[name_end])
                    name_end += 1
                end
                name = value[name_start...name_end]
                str << variable_value(name)
                name_end - position
            end

            private def variable_value(name : String) : String
                @environment.get(name) || ENV[name]? || ""
            end

            private def valid_variable_name?(name : String) : Bool
                return false if name.empty?
                return false unless valid_variable_start?(name[0])

                name[1..].each_char do |char|
                    return false unless valid_variable_char?(char)
                end

                true
            end

            private def valid_variable_start?(char : Char) : Bool
                char == '_' || char.ascii_letter?
            end

            private def valid_variable_char?(char : Char) : Bool
                char == '_' || char.ascii_letter? || char.ascii_number?
            end
        end
    end
end
