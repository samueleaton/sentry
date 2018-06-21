require "yaml"

module Sentry
  FILE_TIMESTAMPS = {} of String => String # {file => timestamp}

  class Config
    # `shard_name` is set as a class property so that it can be inferred from
    # the `shard.yml` in the project directory.
    class_property shard_name : String?

    YAML.mapping(
      display_name: {
        type:    String?,
        getter:  false,
        setter:  false,
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

    property? sets_display_name : Bool = false
    property? sets_build_command : Bool = false
    property? sets_run_command : Bool = false

    # Initializing an empty configuration provides no default values.
    def initialize
      @display_name = nil
      @sets_display_name = false
      @info = false
      @build = nil
      @build_args = ""
      @run = nil
      @run_args = ""
      @watch = [] of String
    end

    def display_name
      @display_name ||= self.class.shard_name
    end

    def display_name=(new_display_name : String)
      @sets_display_name = true
      @display_name = new_display_name
    end

    def display_name!
      display_name.not_nil!
    end

    def build
      @build ||= "crystal build ./src/#{self.class.shard_name}.cr"
    end

    def build=(new_command : String)
      @sets_build_command = true
      @build = new_command
    end

    def build_args
      @build_args.strip.split(" ").reject(&.empty?)
    end

    def run
      @run ||= "./#{self.class.shard_name}"
    end

    def run=(new_command : String)
      @sets_run_command = true
      @run = new_command
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
      self.display_name = other.display_name! if other.sets_display_name?
      self.info = other.info if other.info
      self.build = other.build if other.sets_build_command?
      self.build_args = other.build_args.join(" ") unless other.build_args.empty?
      self.run = other.run if other.sets_run_command?
      self.run_args = other.run_args.join(" ") unless other.run_args.empty?
      self.watch = other.watch unless other.watch.empty?
    end

    def to_s(io : IO)
      io << <<-CONFIG
      🤖  Sentry configuration:
            display name: #{display_name}
            shard name:   #{self.class.shard_name}
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
    property display_name : String
    property should_build = true
    property files = [] of String

    def initialize(
      @display_name : String,
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
      puts "🤖  compiling #{display_name}..."
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
          puts "🤖  killing #{display_name}..."
          app_process.kill
          app_process.wait
        end
      end

      puts "🤖  starting #{display_name}..."
      run_args = @run_args
      if run_args.size > 0
        @app_process = Process.new(@run_command, run_args, output: Process::Redirect::Inherit, error: Process::Redirect::Inherit)
      else
        @app_process = Process.new(@run_command, output: Process::Redirect::Inherit, error: Process::Redirect::Inherit)
      end
    end

    private def get_timestamp(file : String)
      File.info(file).modification_time.epoch.to_s
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
