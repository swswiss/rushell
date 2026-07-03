module Rushell
  module AST
    # A single command: `ls -la > out.txt`
    Command = Struct.new(:words, :redirects, keyword_init: true) do
      def initialize(words: [], redirects: [])
        super
      end
    end

    # A pipeline: `cat f | grep x | wc -l`
    Pipeline = Struct.new(:commands, keyword_init: true)

    # A redirect: kind is :in, :out, :append
    Redirect = Struct.new(:kind, :target, keyword_init: true)
  end
end