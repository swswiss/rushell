# lib/rushell/builtins.rb
module Rushell
  class Builtins
    def initialize(shell)
      @shell = shell
      @env = shell.env
    end

    def builtin?(name) = respond_to?("cmd_#{name}", true)

    # Runs a builtin. Returns exit status integer.
    def run(name, args)
      send("cmd_#{name}", args)
    end

    private

    def cmd_cd(args)
      target = args.first || @env.get("HOME") || Dir.home
      Dir.chdir(target)
      @env.set("PWD", Dir.pwd)
      0
    rescue Errno::ENOENT
      warn "cd: no such directory: #{target}"
      1
    end

    def cmd_export(args)
      args.each do |pair|
        key, val = pair.split("=", 2)
        @env.set(key, val || "") if key
      end
      0
    end

    def cmd_unset(args)
      args.each { |k| @env.unset(k) }
      0
    end

    def cmd_echo(args)
      puts args.join(" ")
      0
    end

    def cmd_pwd(_args)
      puts Dir.pwd
      0
    end

    def cmd_exit(args)
      code = (args.first || "0").to_i
      throw :shell_exit, code
    end
  end
end