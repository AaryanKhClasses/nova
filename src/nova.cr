# require "./nova/shell"
require "./nova/terminal/terminal"

module Nova
    VERSION = "0.1.10a"
end

terminal = Nova::Terminal::Terminal.new
begin
    terminal.raw_mode
    terminal.write("raw mode enabled. press keys. press q to quit.\n")
    loop do
        byte = terminal.read_byte
        break if byte == 'q'.ord
        terminal.write("read byte: #{byte} (#{byte.chr})\n")
    end
ensure
    terminal.restore
    puts
end

# Nova::Shell.new.run
