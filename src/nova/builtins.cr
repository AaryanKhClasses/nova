require "./parser/ast"

module Nova
    module Builtins
        def self.execute(command : Parser::Command) : Bool
            return false if command.words.empty?
            name = command.words[0]
            args = command.words[1..]

            case name
            when "cd"
                cd(args)
            when "pwd"
                pwd
            when "echo"
                echo(args)
            when "exit"
                exit
            else
                return false
            end
            true
        end

        private def self.cd(args : Array(String))
            if args.empty?
                Dir.cd(ENV["HOME"] || "/")
                return
            end

            path = args[0]
            begin
                Dir.cd(path)
            rescue ex : Exception
                puts "cd: #{ex.message}"
            end
        end

        private def self.pwd
            puts Dir.current
        end

        private def self.echo(args : Array(String))
            puts args.join(" ")
        end

        private def self.exit
            Process.exit
        end
    end
end
