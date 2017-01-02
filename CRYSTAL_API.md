# Sentry Crystal API

For use inside a crystal application. This is the core functionality used by the CLI tool.

## Installation

Add this to your `shards.yml`

```yaml
dependencies:
  sentry:
    github: samueleaton/sentry
    branch: master
```

## Usage

Create a Sentry ProcessRunner and then run it:

```ruby
require "sentry"

sentry = Sentry::ProcessRunner.new(
    process_name: "My cool app",
    build_command: "crystal build ./src/my_app.cr",
    run_command: "./my_app",
    files: ["./src/**/*.cr", "./src/**/*.ecr"]
)

sentry.run
```

To stop a Sentry Process Runner, you may need to run the process runner in a separate thread and then use the `kill` method.

```ruby
require "sentry"

sentry = Sentry::ProcessRunner.new(
    process_name: "My cool app",
    build_command: "crystal build ./src/my_app.cr",
    run_command: "./my_app",
    files: ["./src/**/*.cr", "./src/**/*.ecr"]
)

spawn { sentry.run }
sleep 5
sentry.kill

```

If the process runner is not run in a separate thread, it may block the main thread.

### Additional Initialize Params

```ruby
process_runner = Sentry::ProcessRunner.new(
  process_name: "", # String
  build_command: "", # String
  run_command: "", # String
  build_args: [], # Array of String
  run_args: [], # Array of String
  should_build: true, # Bool
  files: [] # Array of String
)
```