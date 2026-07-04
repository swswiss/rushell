# rushell

A miniature Unix shell written in Ruby 3.3 — a hand-built `bash`-like REPL that parses your commands, runs them, and wires them together with pipes and redirection.

## Features

- **Command parsing** — a custom lexer and parser turn your input into a structured AST
- **Pipes** — chain commands together: `ls | grep .rb | wc -l`
- **Redirection** — `>` (write), `>>` (append), and `<` (read from file)
- **Environment variables** — `export NAME=world`, then use `$NAME` or `${NAME}`
- **Built-in commands** — `cd`, `export`, `unset`, `echo`, `pwd`, `exit`
- **External programs** — any program on your `PATH` (`ls`, `cat`, `git`, `python3`, ...) runs as a spawned child process

## Architecture

The code is organized into clean, single-responsibility layers:

| Layer | File | Responsibility |
|-------|------|----------------|
| REPL | `shell.rb` | The read-eval-print loop |
| Lexer | `lexer.rb` | Text → tokens |
| Parser | `parser.rb` | Tokens → AST |
| Executor | `executor.rb` | Runs the AST: pipes, redirection, process spawning |
| Environment | `environment.rb` | Environment variables and state |
| Builtins | `builtins.rb` | In-process commands like `cd` |

## Usage

```bash
chmod +x bin/rushell
./bin/rushell
```

Then type commands at the prompt:

```
rushell $ echo hi $USER | tr a-z A-Z
HI STEFAN
rushell $ ls | grep .rb > files.txt
rushell $ exit
```

You can also run it explicitly with Ruby:

```bash
ruby -Ilib bin/rushell
```

## What I learned

Building this covers the fundamentals of how a shell works under the hood: **IO** (connecting file descriptors with `IO.pipe`), **processes** (`Process.spawn`, `Process.wait2`), and **parsing** (tokenizing and building an AST from raw input).

## Roadmap

- Command sequencing (`;`, `&&`, `||`)
- Glob expansion (`*.rb`)
- Background jobs and job control (`&`, `fg`, `bg`)
- Tilde (`~`) expansion
