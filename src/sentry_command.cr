require "cli"
require "./sentry"
module Sentry
  class SentryCommand < Cli::Command

    command_name "sentry"

    class Options

      string %w(-n --name), desc: "Sets the name of the app process",
      default: "[process_name]"

      string %w(-b --build), desc: "Overrides the default build command",
      default: "crystal build ./src/[process_name].cr"

      string "--build-args", desc: "Specifies arguments for the build command",
             default: ""

      bool "--no-build", desc: "Skips the build step", default: false

      string %w(-r --run), desc: "Overrides the default run command",
      default: "./[process_name]"

      string "--run-args", desc: "Specifies arguments for the run command",
             default: ""

      array %w(-w --watch),
      desc: "Overrides default files and appends to list of watched files",
      default: ["./src/**/*.cr", "./src/**/*.ecr"]

      bool %w(-i --info),
      desc: "Shows the values for build/run commands, build/run args, and watched files",
      default: false

      help

    end

    def run

      if options.info?
        puts "
      name:       #{options.name?}
      build:      #{options.build?}
      build args: #{options.build_args?}
      run:        #{options.run?}
      run args:   #{options.run_args?}
      files:      #{options.watch?}
    "
        exit! code: 0
      end

      process_runner = Sentry::ProcessRunner.new(
        process_name: options.name,
        build_command: options.build,
        run_command: options.run,
        build_args: options.build_args.split(" "),
        run_args: options.run_args.split(" "),
        should_build: !options.no_build?,
        files: options.watch
      )

      process_runner.run

    end
  end
end
