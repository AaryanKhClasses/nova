require "../parser/word"
require "./environment"
require "./globber"
require "./substituter"

module Nova
    module Expander
        class Expander
            getter environment
            @cmd_executor : Nova::Expander::CommandExecutor?

            def initialize(
                @environment : Environment,
                cmd_executor : Nova::Expander::CommandExecutor? = nil
            )
                @cmd_executor = cmd_executor
                @globber = Globber.new

                @substituter = if executor = @cmd_executor
                    Nova::Expander::Substituter.new(executor)
                end
            end

            def expand_word(word : Parser::Word) : Array(String)
                unqouted = String.build do |str|
                    word.parts.each do |part|
                        case part
                        when Parser::LiteralPart
                            expanded = expand_substitutions(part.value)
                            expand_variables(expanded, str)
                        when Parser::SingleQuotedPart
                            str << part.value
                        when Parser::DoubleQuotedPart
                            expanded = expand_substitutions(part.value)
                            expand_variables(expanded, str)
                        end
                    end
                end

                has_unquoted_glob  = word.parts.any? do |part|
                    case part
                    when Parser::LiteralPart
                        contains_glob?(part.value)
                    else
                        false
                    end
                end

                has_unquoted_glob ? @globber.expand(unqouted) : [unqouted]
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

            private def contains_glob?(value : String) : Bool
                value.includes?('*') || value.includes?('?') || value.includes?('[')
            end

            private def expand_substitutions(value : String) : String
                String.build do |str|
                    position = 0
                    while position < value.size
                        if value[position] == '$' && position + 1 < value.size && value[position + 1] == '('
                            closing = find_substitution_end(value, position)
                            if closing.nil?
                                str << value[position]
                                position += 1
                                next
                            end

                            command = value[(position + 2)...closing]
                            @substituter ? str << @substituter.not_nil!.execute(command) : str << value[position..closing]
                            position = closing + 1
                        else
                            str << value[position]
                            position += 1
                        end
                    end
                end
            end

            private def find_substitution_end(value : String, start : Int32) : Int32?
                depth = 0
                position = start + 2
                while position < value.size
                    case value[position]
                    when '('
                        depth += 1
                    when ')'
                        return position if depth == 0
                        depth -= 1
                    end

                    position += 1
                end
                nil
            end
        end
    end
end
