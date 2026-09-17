require "./builtins"
require "./parser/ast"

module Nova
    class Executor
        def execute(program : Parser::Program)
            program.pipelines.each do |pipeline|
                execute_pipeline(pipeline)
            end
        end

        def execute_command(command : Parser::Command) : Process::Status?
            return nil if command.words.empty?

            program = command.words[0]
            args = command.words[1..]

            input_file = nil
            output_file = nil
            error_file = nil
            begin
                input = Process::Redirect::Inherit
                output = Process::Redirect::Inherit
                error = Process::Redirect::Inherit

                command.redirects.each do |redirect|
                    case redirect.type
                    when Parser::RedirectType::Input
                        input_file = File.open(redirect.target, "r")
                        input = input_file
                    when Parser::RedirectType::Output
                        output_file = File.open(redirect.target, "w")
                        output = output_file
                    when Parser::RedirectType::Append
                        output_file = File.open(redirect.target, "a")
                        output = output_file
                    when Parser::RedirectType::Error
                        error_file = File.open(redirect.target, "w")
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
                status
            rescue ex : File::NotFoundError
                STDERR.puts "nova: command not found: #{command}"
                nil
            rescue ex
                STDERR.puts "nova: error executing command: #{ex.message}"
                nil
            ensure
                input_file.try(&.close)
                output_file.try(&.close)
                error_file.try(&.close)
            end
        end

        private def execute_pipeline(pipeline : Parser::Pipeline)
            commands = pipeline.commands
            return if commands.empty?

            if commands.size == 1
                command = commands[0]
                return if Builtins.execute(command)
                execute_command(command)
                return
            end

            processes = [] of Process
            pipes = [] of {IO::FileDescriptor, IO::FileDescriptor}

            begin
                (commands.size - 1).times do
                    pipes << IO.pipe
                end

                commands.each_with_index do |command, index|
                    input = if index == 0
                        Process::Redirect::Inherit
                    else
                        pipes[index - 1][0]
                    end
                    output = if index == commands.size - 1
                        Process::Redirect::Inherit
                    else
                        pipes[index][1]
                    end

                    process = spawn_process(command, input, output)
                    processes << process
                end

                pipes.each do |read_pipe, write_pipe|
                    read_pipe.close unless read_pipe.closed?
                    write_pipe.close unless write_pipe.closed?
                end

                processes.each_with_index do |process, index|
                    status = process.wait
                end
            ensure
                pipes.each do |read_pipe, write_pipe|
                    read_pipe.close unless read_pipe.closed?
                    write_pipe.close unless write_pipe.closed?
                end
            end
        end

        private def spawn_process(command : Parser::Command, input : Process::Redirect | IO::FileDescriptor, output : Process::Redirect | IO::FileDescriptor) : Process
            program = command.words[0]
            args = command.words[1..]

            process_input = input
            process_output = output
            process_error = Process::Redirect::Inherit

            opened_files = [] of File

            begin
                command.redirects.each do |redirect|
                    case redirect.type
                    when Parser::RedirectType::Input
                        file = File.open(redirect.target, "r")
                        opened_files << file
                        process_input = file
                    when Parser::RedirectType::Output
                        file = File.open(redirect.target, "w")
                        opened_files << file
                        process_output = file
                    when Parser::RedirectType::Append
                        file = File.open(redirect.target, "a")
                        opened_files << file
                        process_output = file
                    when Parser::RedirectType::Error
                        file = File.open(redirect.target, "w")
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
    end
end
