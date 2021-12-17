require "yaml"
require "colorize"

module Sentry
  FILE_TIMESTAMPS = {} of String => String # {file => timestamp}

  class Config
    include YAML::Serializable

    # `shard_name` is set as a class property so that it can be inferred from
    # the `shard.yml` in the project directory.
    class_property shard_name : String?

    @[YAML::Field(ignore: true)]
    property? sets_display_name : Bool = false

    @[YAML::Field(ignore: true)]
    property? sets_build_command : Bool = false

    @[YAML::Field(ignore: true)]
    property? sets_run_command : Bool = false

    property info : Bool = false

    property? colorize : Bool = true

    property src_path : String = "./src/#{Sentry::Config.shard_name}.cr"

    property? install_shards : Bool = false

    setter build_args : String = ""

    setter run_args : String = ""

    property watch : Array(String) = ["./src/**/*.cr", "./src/**/*.ecr"]

    property install_shards : Bool = false

    # Initializing an empty configuration provides no default values.
    def initialize
      @display_name = nil
      @sets_display_name = false
      @info = false
      @src_path = "./src/#{Sentry::Config.shard_name}.cr"
      @build = nil
      @build_args = ""
      @run = nil
      @run_args = ""
      @watch = [] of String
      @install_shards = false
      @colorize = true
    end

    @display_name : String?

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

    @build : String?

    def build
      @build ||= "crystal build #{self.src_path}"
    end

    def build=(new_command : String)
      @sets_build_command = true
      @build = new_command
    end

    def build_args
      @build_args.strip.split(" ").reject(&.empty?)
    end

    @run : String?

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

    @[YAML::Field(ignore: true)]
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
      self.install_shards = other.install_shards?
      self.colorize = other.colorize?
      self.src_path = other.src_path
    end

    def to_s(io : IO)
      io << <<-CONFIG
      🤖  Sentry configuration:
            display name:   #{display_name}
            shard name:     #{self.class.shard_name}
            install shards: #{install_shards?}
            info:           #{info}
            build:          #{build}
            build_args:     #{build_args}
            src_path:       #{src_path}
            run:            #{run}
            run_args:       #{run_args}
            watch:          #{watch}
            colorize:       #{colorize?}
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
      should_build = true,
      install_shards = false,
      colorize = true
    )
      @files = files
      @should_build = should_build
      @should_kill = false
      @app_built = false
      @should_install_shards = install_shards
      @colorize = colorize
    end

    private def stdout(str : String)
      if @colorize
        puts str.colorize.fore(:yellow)
      else
        puts str
      end
    end

    private def build_app_process
      stdout "🤖  compiling #{display_name}..."
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
          stdout "🤖  killing #{display_name}..."
          app_process.signal(:kill)
          app_process.wait
        end
      end

      stdout "🤖  starting #{display_name}..."
      run_args = @run_args
      if run_args.size > 0
        @app_process = Process.new(@run_command, run_args, output: Process::Redirect::Inherit, error: Process::Redirect::Inherit)
      else
        @app_process = Process.new(@run_command, output: Process::Redirect::Inherit, error: Process::Redirect::Inherit)
      end
    end

    private def get_timestamp(file : String)
      File.info(file).modification_time.to_unix.to_s
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
        stdout "🤖  Compile time errors detected. SentryBot shutting down..."
        exit 1
      end
    end

    # Scans all of the `@files`
    #
    def scan_files
      file_changed = false
      app_process = @app_process
      files = @files
      begin
        Dir.glob(files) do |file|
          timestamp = get_timestamp(file)
          if FILE_TIMESTAMPS[file]? && FILE_TIMESTAMPS[file] != timestamp
            FILE_TIMESTAMPS[file] = timestamp
            file_changed = true
            stdout "🤖  #{file}"
          elsif FILE_TIMESTAMPS[file]?.nil?
            stdout "🤖  watching file: #{file}"
            FILE_TIMESTAMPS[file] = timestamp
            file_changed = true if (app_process && !app_process.terminated?)
          end
        end
      rescue ex : File::Error
        # The underlining lib for reading directories will fail very rarely, crashing Sentry
        # This catches that error and allows Sentry to carry on normally
        # https://github.com/crystal-lang/crystal/blob/677422167cbcce0aeea49531896dbdcadd2762db/src/crystal/system/unix/dir.cr#L19
      end

      start_app() if (file_changed || app_process.nil?)
    end

    def run_install_shards
      stdout "🤖  Installing shards..."
      install_result = Process.run("shards", ["install"], shell: true, output: Process::Redirect::Inherit, error: Process::Redirect::Inherit)
      if !install_result || !install_result.success?
        stdout "🤖  Error installing shards. SentryBot shutting down..."
        exit 1
      end
    end

    def run
      stdout "🤖  Your SentryBot is vigilant. beep-boop..."

      run_install_shards if @should_install_shards

      loop do
        if @should_kill
          stdout "🤖  Powering down your SentryBot..."
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
