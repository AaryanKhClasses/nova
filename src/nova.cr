require "./nova/shell"
require "./nova/lexer/lexer"
require "./nova/parser/parser"

module Nova
    VERSION = "0.1.7a"
end

Nova::Shell.new.run
