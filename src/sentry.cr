require "yaml"

module Sentry
  FILE_TIMESTAMPS = {} of String => String # {file => timestamp}

  class Config
    # `process_name` is set as a class property so that it can be inferred from
    # the `shard.yml` in the project directory.
    class_property! process_name : String?

    YAML.mapping(
      name: {
        type:    String?,
        getter:  false,
        default: nil,
      },
      info: {
        type:    Bool,
        default: false,
      },
      build: {
        type:    String?,
        getter:  false,
        default: nil,
      },
      build_args: {
        type:    String,
        getter:  false,
        default: "",
      },
      run: {
        type:    String?,
        getter:  false,
        default: nil,
      },
      run_args: {
        type:    String,
        getter:  false,
        default: "",
      },
      watch: {
        type:    Array(String),
        default: ["./src/**/*.cr", "./src/**/*.ecr"],
      }
    )

    # Initializing an empty configuration provides no default values.
    def initialize
      @name = nil
      @info = false
      @build = nil
      @build_args = ""
      @run = nil
      @run_args = ""
      @watch = [] of String
    end

    def name
      @name ||= self.class.process_name
    end

    def build
      @build ||= "crystal build ./src/#{name}.cr"
    end

    def build_args
      @build_args.strip.split(" ").reject(&.empty?)
    end

    def run
      @run ||= "./#{name}"
    end

    def run_args
      @run_args.strip.split(" ").reject(&.empty?)
    end

    setter should_build : Bool = true

    def should_build?
      @should_build ||= begin
        if build_command = @build
          build_command.empty?
        else
          false
        end
      end
    end

    def merge!(other : self)
      self.name = other.name if other.name
      self.info = other.info if other.info
      self.build = other.build if other.build
      self.build_args = other.build_args.join(" ") unless other.build_args.empty?
      self.run = other.run if other.run
      self.run_args = other.run_args.join(" ") unless other.run_args.empty?
      self.watch = other.watch unless other.watch.empty?
    end

    def to_s(io : IO)
      io << <<-CONFIG
      🤖  Sentry configuration:
            process_name: #{name}
            info:         #{info}
            build:        #{build}
            build_args:   #{build_args}
            run:          #{run}
            run_args:     #{run_args}
            watch:        #{watch}
      CONFIG
    end
  end

  class ProcessRunner
    getter app_process : (Nil | Process) = nil
    property process_name : String
    property should_build = true
    property files = [] of String

    def initialize(
      @process_name : String,
      @build_command : String,
      @run_command : String,
      @build_args : Array(String) = [] of String,
      @run_args : Array(String) = [] of String,
      files = [] of String,
      should_build = true
    )
      @files = files
      @should_build = should_build
      @should_kill = false
      @app_built = false
    end

    private def build_app_process
      puts "🤖  compiling #{process_name}..."
      build_args = @build_args
      if build_args.size > 0
        Process.run(@build_command, build_args, shell: true, output: Process::Redirect::Inherit, error: Process::Redirect::Inherit)
      else
        Process.run(@build_command, shell: true, output: Process::Redirect::Inherit, error: Process::Redirect::Inherit)
      end
    end

    private def create_app_process
      app_process = @app_process
      if app_process.is_a? Process
        unless app_process.terminated?
          puts "🤖  killing #{process_name}..."
          app_process.kill
        end
      end

      puts "🤖  starting #{process_name}..."
      run_args = @run_args
      if run_args.size > 0
        @app_process = Process.new(@run_command, run_args, output: Process::Redirect::Inherit, error: Process::Redirect::Inherit)
      else
        @app_process = Process.new(@run_command, output: Process::Redirect::Inherit, error: Process::Redirect::Inherit)
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

    def run
      puts "🤖  Your SentryBot is vigilant. beep-boop..."

      loop do
        if @should_kill
          puts "🤖  Powering down your SentryBot..."
          break
        end
        scan_files
        sleep 1
      end
    end

    def kill
      @should_kill = true
    end
  end
end
