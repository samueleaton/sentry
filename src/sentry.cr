module Sentry
  FILES = ["./src/**/*.cr"]
  BUILD_APP_COMMAND = ENV["BUILD"]? || "crystal build ./src/[app_name].cr"
  RUN_APP_COMMAND = ENV["RUN"]? || "./[app_name]"
  FILE_TIMESTAMPS = {} of String => String # {file => timestamp}

  class ProcessRunner
    getter  app_process : (Nil | Process) = nil,
            build_process : (Nil | Process::Status) = nil
    
    private def build_app_process
      @build_process = Process.run(BUILD_APP_COMMAND, output: true, error: true)
    end

    private def create_app_process
      @app_process = Process.new(RUN_APP_COMMAND, shell: true, output: true, error: true)
    end

    private def get_timestamp(file : String)
      File.stat(file).mtime.to_s("%Y%m%d%H%M%S")
    end

    def start_app
      app_process = @app_process
      if app_process.is_a? Process
        app_process.kill unless app_process.terminated?
      end

      puts "compiling app..."
      build_result = build_app_process()
      create_app_process() if build_result.success?
    end

    def scan_files
      file_changed = false
      app_process = @app_process

      Dir.glob(FILES) do |file|
        timestamp = get_timestamp(file)
        if FILE_TIMESTAMPS[file]? && FILE_TIMESTAMPS[file] != timestamp
          FILE_TIMESTAMPS[file] = timestamp
          file_changed = true
          puts file
        elsif FILE_TIMESTAMPS[file]?.nil?
          puts "watching file: #{file}"
          FILE_TIMESTAMPS[file] = timestamp
          file_changed = true if (app_process && !app_process.terminated?)
        end
      end

      start_app() if (file_changed || !app_process)
    end
  end
end

process_runner = Sentry::ProcessRunner.new

loop do
  process_runner.scan_files
  sleep 1
end
