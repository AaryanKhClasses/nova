module Nova
    module Terminal
        enum KeyType
            Character
            Enter
            Backspace
            Escape
            Left
            Right
            Up
            Down
            Home
            End
            CtrlC
            CtrlD
            CtrlL
        end

        struct Key
            getter type
            getter character

            def initialize(@type : KeyType, @character : Char? = nil)
            end
        end
    end
end
