module Rushell
  class Lexer
    Token = Struct.new(:type, :value)

    def initialize(input)
      @input = input
      @pos = 0
    end

    def tokenize
      tokens = []
      while (tok = next_token)
        tokens << tok
      end
      tokens
    end

    private

    def next_token
      skip_whitespace
      return nil if eof?

      c = peek
      case c
      when "|" then advance; Token.new(:pipe, "|")
      when ">"
        advance
        if peek == ">"
          advance; Token.new(:append, ">>")
        else
          Token.new(:redirect_out, ">")
        end
      when "<" then advance; Token.new(:redirect_in, "<")
      when '"', "'" then read_quoted(c)
      else read_word
      end
    end

    def read_word
      start = @pos
      buf = +""
      until eof? || whitespace?(peek) || special?(peek)
        if peek == '"' || peek == "'"
          buf << read_quoted(peek).value
        else
          buf << advance
        end
      end
      Token.new(:word, buf)
    end

    def read_quoted(quote)
      advance # opening quote
      buf = +""
      until eof? || peek == quote
        buf << advance
      end
      advance # closing quote
      Token.new(:word, buf)
    end

    def skip_whitespace
      advance while !eof? && whitespace?(peek)
    end

    def peek = @input[@pos]
    def advance = @input[@pos].tap { @pos += 1 }
    def eof? = @pos >= @input.length
    def whitespace?(c) = c == " " || c == "\t"
    def special?(c) = ["|", ">", "<"].include?(c)
  end
end