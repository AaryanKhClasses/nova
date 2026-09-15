require "./nova/shell"
require "./nova/lexer/lexer"

module Nova
    VERSION = "0.1.2"
end

Nova::Shell.new.run
