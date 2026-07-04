# lib/rushell/shell.rb
require "readline"
require_relative "environment"
require_relative "lexer"
require_relative "parser"
require_relative "executor"
require_relative "builtins"

module Rushell
  class Shell
    attr_reader :env, :builtins

    def initialize
      @env = Environment.new
      @builtins = Builtins.new(self)
      @executor = Executor.new(self)
      @last_status = 0
    end

    def run
      exit_code = catch(:shell_exit) do
        loop do
          line = Readline.readline(prompt, true)
          break 0 if line.nil? # Ctrl-D
          next if line.strip.empty?

          process(line)
        end
        0
      end
      exit(exit_code)
    end

    private

    def process(line)
      tokens = Lexer.new(line).tokenize
      pipeline = Parser.new(tokens).parse
      return unless pipeline
      @last_status = @executor.execute(pipeline)
    rescue Parser::SyntaxError => e
      warn "rushell: syntax error: #{e.message}"
      @last_status = 2
    rescue Interrupt
      puts # clean newline on Ctrl-C
    end

    def prompt
      "#{Dir.pwd.split('/').last || '/'} $ "
    end
  end
end