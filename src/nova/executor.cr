module Nova
    class Executor
        def execute(input : String)
            parts = input.split
            return if parts.empty?

            command = parts[0]
            args = parts[1..]

            begin
                process = Process.new(
                    command, args,
                    input: Process::Redirect::Inherit,
                    output: Process::Redirect::Inherit,
                    error: Process::Redirect::Inherit
                )
                status = process.wait

                unless status.success?
                    STDERR.puts "nova: process exited with status #{status.exit_code}"
                end
            rescue ex : File::NotFoundError
                STDERR.puts "nova: command not found: #{command}"
            rescue ex
                STDERR.puts "nova: error executing command: #{ex.message}"
            end
        end
    end
end
