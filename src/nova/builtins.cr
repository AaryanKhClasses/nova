require "./parser/ast"

module Nova
    module Builtins
        def self.execute(command : Parser::Command, input : IO = STDIN, output : IO = STDOUT, error : IO = STDERR) : Int32?
            return nil if command.words.empty?
            name = command.words[0]
            args = command.words[1..]

            case name
            when "cd"
                cd(args, error)
            when "pwd"
                pwd(output)
            when "echo"
                echo(args, output)
            when "exit"
                exit
            else
                nil
            end
        end

        private def self.cd(args : Array(String), error : IO) : Int32
            path = args.empty? ? (ENV["HOME"] || "/") : args[0]

            begin
                Dir.cd(path)
                0
            rescue ex : Exception
                error.puts "cd: #{ex.message}"
                1
            end
        end

        private def self.pwd(output : IO) : Int32
            output.puts Dir.current
            0
        end

        private def self.echo(args : Array(String), output : IO) : Int32
            output.puts args.join(" ")
            0
        end

        private def self.exit
            Process.exit
        end
    end
end
