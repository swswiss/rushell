# lib/rushell/executor.rb
module Rushell
  class Executor
    def initialize(shell)
      @shell = shell
      @env = shell.env
      @builtins = shell.builtins
    end

    # Execute a Pipeline AST. Returns exit status of last command.
    def execute(pipeline)
      commands = pipeline.commands
      return execute_single(commands.first) if commands.size == 1

      execute_pipeline(commands)
    end

    private

    # --- Single command (may be builtin or external) ---
    def execute_single(cmd)
      words = expand(cmd.words)
      name, *args = words

      # Builtins run in-process (so `cd` etc. affect the shell).
      # We still honor redirects by temporarily swapping IO.
      if @builtins.builtin?(name)
        with_redirects(cmd.redirects) { @builtins.run(name, args) }
      else
        spawn_external(words, cmd.redirects)
      end
    end

    def spawn_external(words, redirects)
      opts = redirect_options(redirects)
      pid = Process.spawn(@env.export_env, *words, opts)
      _, status = Process.wait2(pid)
      status.exitstatus
    rescue Errno::ENOENT
      warn "#{words.first}: command not found"
      127
    end

    # --- Pipeline: connect stdout -> stdin across commands ---
    def execute_pipeline(commands)
      pipes = (commands.size - 1).times.map { IO.pipe }
      pids = []

      commands.each_with_index do |cmd, i|
        words = expand(cmd.words)
        opts = redirect_options(cmd.redirects)

        opts[:in]  = pipes[i - 1][0] if i > 0                  # read from prev pipe
        opts[:out] = pipes[i][1]     if i < commands.size - 1  # write to next pipe

        pids << Process.spawn(@env.export_env, *words, opts)
      end

      # Parent closes all pipe ends so EOF propagates correctly.
      pipes.each { |r, w| r.close; w.close }

      statuses = pids.map { |pid| Process.wait2(pid)[1] }
      statuses.last.exitstatus
    end

    # --- Redirection helpers ---
    def redirect_options(redirects)
      opts = {}
      redirects.each do |r|
        case r.kind
        when :out    then opts[:out] = [r.target, "w"]
        when :append then opts[:out] = [r.target, "a"]
        when :in     then opts[:in]  = [r.target, "r"]
        end
      end
      opts
    end

    # For builtins: temporarily redirect $stdout / $stdin.
    def with_redirects(redirects)
      saved_out, saved_in = $stdout, $stdin
      redirects.each do |r|
        case r.kind
        when :out    then $stdout = File.open(r.target, "w")
        when :append then $stdout = File.open(r.target, "a")
        when :in     then $stdin  = File.open(r.target, "r")
        end
      end
      yield
    ensure
      $stdout.close if $stdout != saved_out
      $stdin.close  if $stdin  != saved_in
      $stdout, $stdin = saved_out, saved_in
    end

    # --- Variable expansion: $VAR and ${VAR} ---
    def expand(words)
      words.map do |w|
        w.gsub(/\$\{(\w+)\}|\$(\w+)/) do
          @env.get($1 || $2).to_s
        end
      end
    end
  end
end