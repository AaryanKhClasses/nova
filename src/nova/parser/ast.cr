module Nova
    module Parser
        abstract class ASTNode
        end

        class Program < ASTNode
            getter pipelines
            def initialize
                @pipelines = [] of Pipeline
            end

            def add_pipeline(pipeline : Pipeline)
                @pipelines << pipeline
            end
        end

        class Pipeline < ASTNode
            getter commands
            property background

            def initialize
                @commands = [] of Command
                @background = false
            end

            def add_command(command : Command)
                @commands << command
            end
        end

        class Command < ASTNode
            getter words
            getter redirects

            def initialize
                @words = [] of String
                @redirects = [] of Redirect
            end

            def add_word(word : String)
                @words << word
            end

            def add_redirect(redirect : Redirect)
                @redirects << redirect
            end
        end

        enum RedirectType
            Input
            Output
            Append
            Error
        end

        class Redirect < ASTNode
            getter type
            getter target

            def initialize(type : RedirectType, target : String)
                @type = type
                @target = target
            end
        end

        # ! DEBUG
        class ASTPrinter
            def self.print(program : Program)
                puts "Program"
                program.pipelines.each_with_index do |pipeline, pipeline_index|
                    puts " Pipeline #{pipeline_index}"
                    pipeline.commands.each_with_index do |command, command_index|
                        puts "  Command #{command_index}"
                        command.words.each do |word|
                            puts "   Word: #{word}"
                        end
                        command.redirects.each do |redirect|
                            puts "   Redirect: #{redirect.type} -> #{redirect.target}"
                        end
                    end
                    puts "  Background: #{pipeline.background}"
                end
            end
        end
    end
end
