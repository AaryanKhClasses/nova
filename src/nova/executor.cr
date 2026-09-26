require "./builtins"
require "./parser/ast"
require "./expander/expander"
require "./lexer/lexer"
require "./parser/parser"

module Nova
    class Executor
        def initialize
            @environment = Expander::Environment.new
            @expander = Expander::Expander.new(
                @environment,
                ->(command : String, output : IO) {
                    execute_substitution(command, output)
                }
            )
        end

        def execute(program : Parser::Program, input : IO = STDIN, output : IO = STDOUT, error : IO = STDERR) : Int32
            status = 0
            program.pipelines.each do |pipeline|
                status = execute_pipeline(pipeline, input, output, error)
            end

            @environment.set_last_status(status)
            status
        end

        def execute_command(command : Parser::Command, input : IO, output : IO, error : IO) : Int32
            return 0 if command.words.empty?

            words = command_arguments(command)
            program = words[0]
            args = words[1..]

            input_file = nil
            output_file = nil
            error_file = nil
            begin
                process_input = input
                process_output = output
                process_error = error

                command.redirects.each do |redirect|
                    target = @expander.expand_string(redirect.target)
                    case redirect.type
                    when Parser::RedirectType::Input
                        input_file = File.open(target, "r")
                        input = input_file
                    when Parser::RedirectType::Output
                        output_file = File.open(target, "w")
                        output = output_file
                    when Parser::RedirectType::Append
                        output_file = File.open(target, "a")
                        output = output_file
                    when Parser::RedirectType::Error
                        error_file = File.open(target, "w")
                        error = error_file
                    end
                end

                process = Process.new(
                    program, args,
                    input: input,
                    output: output,
                    error: error
                )
                status = process.wait
                status.exit_code
            rescue ex : File::NotFoundError
                STDERR.puts "nova: command not found: #{program}"
                127
            rescue ex
                STDERR.puts "nova: error executing command: #{ex.message}"
                1
            ensure
                input_file.try(&.close)
                output_file.try(&.close)
                error_file.try(&.close)
            end
        end

        private def execute_pipeline(pipeline : Parser::Pipeline, input : IO, output : IO, error : IO) : Int32
            commands = pipeline.commands
            return 0 if commands.empty?

            if commands.size == 1
                command = commands[0]
                assignment_status = execute_assignment(command)
                return 0 if assignment_status
                builtin_status = execute_builtin(command, input, output, error)
                return builtin_status unless builtin_status.nil?
                return execute_command(command, input, output, error)
            end

            processes = [] of Process
            pipes = [] of {IO::FileDescriptor, IO::FileDescriptor}

            begin
                (commands.size - 1).times do
                    pipes << IO.pipe
                end

                commands.each_with_index do |command, index|
                    input = index == 0 ? Process::Redirect::Inherit : pipes[index - 1][0]
                    output = index == commands.size - 1 ? Process::Redirect::Inherit : pipes[index][1]
                    process = spawn_process(command, input, output)
                    processes << process
                end

                pipes.each do |read_pipe, write_pipe|
                    read_pipe.close unless read_pipe.closed?
                    write_pipe.close unless write_pipe.closed?
                end

                status = 0
                processes.each_with_index do |process, index|
                    status = process.wait.exit_code
                end
                status
            ensure
                pipes.each do |read_pipe, write_pipe|
                    read_pipe.close unless read_pipe.closed?
                    write_pipe.close unless write_pipe.closed?
                end
            end
        end

        private def spawn_process(command : Parser::Command, input : Process::Redirect | IO::FileDescriptor, output : Process::Redirect | IO::FileDescriptor) : Process
            words = command_arguments(command)
            program = words[0]
            args = words[1..]

            process_input = input
            process_output = output
            process_error = Process::Redirect::Inherit

            opened_files = [] of File

            begin
                command.redirects.each do |redirect|
                    target = @expander.expand_string(redirect.target)
                    case redirect.type
                    when Parser::RedirectType::Input
                        file = File.open(target, "r")
                        opened_files << file
                        process_input = file
                    when Parser::RedirectType::Output
                        file = File.open(target, "w")
                        opened_files << file
                        process_output = file
                    when Parser::RedirectType::Append
                        file = File.open(target, "a")
                        opened_files << file
                        process_output = file
                    when Parser::RedirectType::Error
                        file = File.open(target, "w")
                        opened_files << file
                        process_error = file
                    end
                end

                process = Process.new(
                    program, args,
                    input: process_input,
                    output: process_output,
                    error: process_error
                )
                process
            ensure
                opened_files.each(&.close)
            end
        end

        private def execute_builtin(command : Parser::Command, input : IO, output : IO, error : IO) : Int32?
            builtin_input = input
            builtin_output = output
            builtin_error = error

            input_file = nil
            output_file = nil
            error_file = nil

            begin
                command.redirects.each do |redirect|
                    target = @expander.expand_string(redirect.target)
                    case redirect.type
                    when Parser::RedirectType::Input
                        input_file = File.open(target, "r")
                        builtin_input = input_file
                    when Parser::RedirectType::Output
                        output_file = File.open(target, "w")
                        builtin_output = output_file
                    when Parser::RedirectType::Append
                        output_file = File.open(target, "a")
                        builtin_output = output_file
                    when Parser::RedirectType::Error
                        error_file = File.open(target, "w")
                        builtin_error = error_file
                    end
                end
                words = command_arguments(command)
                result = Builtins.execute(words, builtin_input, builtin_output, builtin_error)
                result
            ensure
                input_file.try(&.close)
                output_file.try(&.close)
                error_file.try(&.close)
            end
        end

        private def execute_command_with_io(command : Parser::Command, input : IO, output : IO, error : IO) : Bool
            result = Builtins.execute(command, input, output, error)
            !result.nil?
        end

        private def spawn_builtin(command : Parser::Command, input : IO, output : IO, error : IO) : Fiber
            spawn do
                input_file = nil
                output_file = nil
                error_file = nil

                begin
                    process_input = input
                    process_output = output
                    process_error = error

                    commands.redirects.each do |redirect|
                        target = @expander.expand_string(redirect.target)
                        case redirect.type
                        when Parser::RedirectType::Input
                            input_file = File.open(target, "r")
                            process_input = input_file
                        when Parser::RedirectType::Output
                            output_file = File.open(target, "w")
                            process_output = output_file
                        when Parser::RedirectType::Append
                            output_file = File.open(target, "a")
                            process_output = output_file
                        when Parser::RedirectType::Error
                            error_file = File.open(target, "w")
                            process_error = error_file
                        end
                    end

                    Builtins.execute(command, process_input, process_output, process_error)
                ensure
                    input_file.try(&.close)
                    output_file.try(&.close)
                    error_file.try(&.close)
                end
            end
        end

        private def command_arguments(command : Parser::Command) : Array(String)
            command.words.flat_map do |word|
                @expander.expand_word(word)
            end
        end

        private def execute_assignment(command : Parser::Command) : Bool
            return false unless command.words.size == 1
            return false unless command.redirects.empty?

            expanded = @expander.expand_word(command.words[0])
            return false unless expanded.size == 1

            raw = expanded[0]
            return true if raw.match(/\A\$[A-Za-z_][A-Za-z0-9_]*=/)

            match = raw.match(/\A([A-Za-z_][A-Za-z0-9_]*)=(.*)\z/)
            return false unless match

            @environment.set(match[1], match[2])
            true
        end

        private def expand_redirect_target(target : String) : String
            @expander.expand_string(target)
        end

        private def execute_substitution(command : String, output : IO) : Int32
            lexer = Lexer::Lexer.new(command)
            tokens = lexer.tokenize
            parser = Parser::Parser.new(tokens)
            program = parser.parse
            execute(program, input: STDIN, output: output, error: STDERR)
        end
    end
end
