require "option_parser"

build_command = "crystal build ./src/[app_name].cr"
build_args = [] of String
run_command = "./[app_name]"
run_args = [] of String
files = ["./src/**/*.cr", "./src/**/*.ecr"]
files_cleared = false
show_help = false
should_build = true

OptionParser.parse! do |parser|
  parser.banner = "Usage: ./sentry [options]"
  parser.on(
    "-b COMMAND",
    "--build=COMMAND",
    "Overrides the default build command") { |command| build_command = command }
  parser.on(
    "--build-args=ARGS",
    "Specifies arguments for the build command") do |args|
    args_arr = args.strip.split(" ")
    build_args = args_arr if args_arr.size > 0
  end
  parser.on(
    "--no-build",
    "Skips the build step") { should_build = false }
  parser.on(
    "-r COMMAND",
    "--run=COMMAND",
    "Overrides the default run command") { |command| run_command = command }
  parser.on(
    "--run-args=ARGS",
    "Specifies arguments for the run command") do |args|
    args_arr = args.strip.split(" ")
    run_args = args_arr if args_arr.size > 0
  end
  parser.on(
    "-w FILE",
    "--watch=FILE",
    "Overrides default files and appends to list of watched files") do |file|
    unless files_cleared
      files.clear
      files_cleared = true
    end
    files << file
  end
  parser.on(
    "-i",
    "--info",
    "Shows the values for build/run commands, build/run args, and watched files") do
    puts "
      build:      #{build_command}
      build args: #{build_args}
      run:        #{run_command}
      run args:   #{run_args}
      files:      #{files}
    "
  end
  parser.on(
    "-h",
    "--help",
    "Show this help") do
    puts parser
    exit 0
  end
end

module Sentry
  FILE_TIMESTAMPS = {} of String => String # {file => timestamp}

  class ProcessRunner
    getter app_process : (Nil | Process) = nil
    property should_build : Bool = true
    property files = [] of String

    def initialize(
                   build_command : String,
                   build_args : Array(String),
                   run_command : String,
                   run_args : Array(String))
      @app_built = false
      @build_command = build_command
      @build_args = build_args
      @run_command = run_command
      @run_args = run_args
    end

    private def build_app_process
      puts "🤖  compiling [app_name]..."
      build_args = @build_args
      if build_args.size > 0
        Process.run(@build_command, build_args, shell: true, output: true, error: true)
      else
        Process.run(@build_command, shell: true, output: true, error: true)
      end
    end

    private def create_app_process
      app_process = @app_process
      if app_process.is_a? Process
        unless app_process.terminated?
          puts "🤖  killing [app_name]..."
          app_process.kill
        end
      end

      puts "🤖  starting [app_name]..."
      run_args = @run_args
      if run_args.size > 0
        @app_process = Process.new(@run_command, run_args, output: true, error: true)
      else
        @app_process = Process.new(@run_command, output: true, error: true)
      end
    end

    private def get_timestamp(file : String)
      File.stat(file).mtime.to_s("%Y%m%d%H%M%S")
    end

    # Compiles and starts the application
    #
    def start_app
      return create_app_process unless @should_build
      build_result = build_app_process()
      if build_result && build_result.success?
        @app_built = true
        create_app_process()
      elsif !@app_built # if build fails on first time compiling, then exit
        puts "🤖  Compile time errors detected. SentryBot shutting down..."
        exit 1
      end
    end

    # Scans all of the `@files`
    #
    def scan_files
      file_changed = false
      app_process = @app_process
      files = @files
      Dir.glob(files) do |file|
        timestamp = get_timestamp(file)
        if FILE_TIMESTAMPS[file]? && FILE_TIMESTAMPS[file] != timestamp
          FILE_TIMESTAMPS[file] = timestamp
          file_changed = true
          puts "🤖  #{file}"
        elsif FILE_TIMESTAMPS[file]?.nil?
          puts "🤖  watching file: #{file}"
          FILE_TIMESTAMPS[file] = timestamp
          file_changed = true if (app_process && !app_process.terminated?)
        end
      end

      start_app() if (file_changed || app_process.nil?)
    end
  end
end

process_runner = Sentry::ProcessRunner.new(
  build_command: build_command,
  build_args: build_args,
  run_command: run_command,
  run_args: run_args
)
process_runner.should_build = should_build
process_runner.files = files

puts "🤖  Your SentryBot is vigilant. beep-boop..."

loop do
  process_runner.scan_files
  sleep 1
end
