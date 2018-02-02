require "option_parser"
require "./sentry"

process_name = nil
CONFIG_FILE_NAME = ".sentry.yml"

begin
  shard_yml = YAML.parse File.read("shard.yml")
  name = shard_yml["name"]?
  process_name = name.as_s if name
rescue e
end

Sentry::Config.process_name = process_name

config_yaml = ""
if File.exists?(CONFIG_FILE_NAME)
  config_yaml = File.read(CONFIG_FILE_NAME)
end

config = Sentry::Config.from_yaml(config_yaml)



files_cleared = false

OptionParser.parse! do |parser|
  parser.banner = "Usage: ./sentry [options]"
  parser.on(
    "-n NAME",
    "--name=NAME",
    "Sets the name of the app process (current name: #{config.name})") { |name| config.name = name }
  parser.on(
    "-b COMMAND",
    "--build=COMMAND",
    "Overrides the default build command") { |command| config.build = command }
  parser.on(
    "--build-args=ARGS",
    "Specifies arguments for the build command") { |args| config.build_args = args }
  parser.on(
    "--no-build",
    "Skips the build step") { config.should_build = false }
  parser.on(
    "-r COMMAND",
    "--run=COMMAND",
    "Overrides the default run command") { |command| config.run = command }
  parser.on(
    "--run-args=ARGS",
    "Specifies arguments for the run command") { |args| config.run_args = args }
  parser.on(
    "-w FILE",
    "--watch=FILE",
    "Overrides default files and appends to list of watched files") do |file|
    unless files_cleared
      config.watch.clear
      files_cleared = true
    end
    config.watch << file
  end
  parser.on(
    "-i",
    "--info",
    "Shows the values for build/run commands, build/run args, and watched files") do
    config.info = true
  end
  parser.on(
    "-h",
    "--help",
    "Show this help") do
    puts parser
    exit 0
  end
end

if config.info
  puts config
end

if config.name
  process_runner = Sentry::ProcessRunner.new(
    process_name: config.name,
    build_command: config.build,
    run_command: config.run,
    build_args: config.build_args,
    run_args: config.run_args,
    should_build: config.should_build?,
    files: config.watch
  )

  process_runner.run
else
  puts "🤖  Sentry error: 'name' not given and not found in shard.yml"
  exit 1
end
