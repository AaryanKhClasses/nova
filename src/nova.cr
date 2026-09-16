require "./nova/shell"
require "./nova/lexer/lexer"
require "./nova/parser/parser"

module Nova
    VERSION = "0.1.4"
end

Nova::Shell.new.run
