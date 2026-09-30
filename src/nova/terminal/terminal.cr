{% if flag?(:linux) %}
    @[Link("c")]
    lib LibC
        struct Termios
            c_iflag : UInt
            c_oflag : UInt
            c_cflag : UInt
            c_lflag : UInt
            c_line : UInt8
            c_cc : StaticArray(UInt8, 32)
            c_ispeed : UInt
            c_ospeed : UInt
        end

        fun tcgetattr(fd : Int32, termios_p : Termios*) : Int
        fun tcsetattr(fd : Int32, optional_actions : Int32, termios_p : Termios*) : Int
    end
{% end %}

module Nova
    module Terminal
        class Terminal
            TCSANOW = 0
            ICANON = 0x0002_u32
            ECHO = 0x0008_u32
            ISIG = 0x0001_u32
            IEXTEN = 0x8000_u32

            def initialize(@input : IO = STDIN, @output : IO = STDOUT)
                @raw_mode = false
                @original_termios = nil
            end

            def raw_mode
                return if @raw_mode

                {% if flag?(:linux) %}
                    enable_raw_mode
                {% else %}
                    raise "raw mode is not supported on this platform"
                {% end %}
            end

            def restore
                return unless @raw_mode

                {% if flag?(:linux) %}
                    restore_terminal
                {% end %}
            end

            def read_byte : UInt8
                byte = @input.get_byte
                raise "unexpected end of terminal input" if byte.nil?
                byte
            end

            def write(value : String)
                @output.print(value)
                @output.flush
            end

            private def enable_raw_mode
                fd = @input.fd
                original = LibC::Termios.new
                result = LibC.tcgetattr(fd, pointerof(original))
                raise "tcgetattr failed" unless result == 0

                @original_termios = original
                raw = original
                raw.clflag &= ~(ICANON | ECHO | ISIG | IEXTEN)
                result = LibC.tcsetattr(fd, TCSANOW, pointerof(raw))
                raise "tcsetattr failed" unless result == 0
                @raw_mode = true
            end

            private def restore_terminal
                original = @original_termios
                return if original.nil?

                result = LibC.tcsetattr(@input.fd, TCSANOW, pointerof(original))
                raise "tcsetattr failed" unless result == 0
                @raw_mode = false
                @original_termios = nil
            end
        end
    end
end
