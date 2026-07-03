module Rushell
  class Environment
    def initialize
      @vars = ENV.to_h
    end

    def get(key)  = @vars[key]
    def set(key, value) = @vars[key] = value.to_s
    def unset(key) = @vars.delete(key)
    def to_h = @vars.dup

    # Snapshot for child process spawning
    def export_env = @vars
  end
end