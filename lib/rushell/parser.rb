# lib/rushell/parser.rb
require_relative "ast"

module Rushell
  class Parser
    class SyntaxError < StandardError; end

    def initialize(tokens)
      @tokens = tokens
      @pos = 0
    end

    # pipeline := command ('|' command)*
    def parse
      return nil if @tokens.empty?
      commands = [parse_command]
      while match?(:pipe)
        advance
        commands << parse_command
      end
      AST::Pipeline.new(commands: commands)
    end

    private

    def parse_command
      words = []
      redirects = []

      loop do
        tok = peek
        break if tok.nil? || tok.type == :pipe

        case tok.type
        when :word
          words << advance.value
        when :redirect_out
          advance; redirects << AST::Redirect.new(kind: :out, target: expect_word)
        when :append
          advance; redirects << AST::Redirect.new(kind: :append, target: expect_word)
        when :redirect_in
          advance; redirects << AST::Redirect.new(kind: :in, target: expect_word)
        else
          raise SyntaxError, "unexpected token #{tok.type}"
        end
      end

      raise SyntaxError, "empty command" if words.empty?
      AST::Command.new(words: words, redirects: redirects)
    end

    def expect_word
      tok = advance
      raise SyntaxError, "expected filename after redirect" unless tok&.type == :word
      tok.value
    end

    def peek = @tokens[@pos]
    def advance = @tokens[@pos].tap { @pos += 1 }
    def match?(type) = peek&.type == type
  end
end