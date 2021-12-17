<br>
<p align="center">
<img width="350" title="cubbie" alt="cubbie!" src="https://raw.githubusercontent.com/samueleaton/design/master/sentry.png">
</p>
<br>

# Sentry 🤖

Build/Runs your crystal application, watches files, and rebuilds/reruns app on file changes

## Installation

To install in your project, from the root directory of your project, run:

```bash
curl -fsSLo- https://raw.githubusercontent.com/samueleaton/sentry/master/install.cr | crystal eval
```

If using Crystal version `0.24.2` try the following:

```bash
curl -fsSLo- https://raw.githubusercontent.com/samueleaton/sentry/crystal-v0.24.2/install.cr | crystal eval
```

If using Crystal version `0.23.1` or lower try the following:

```bash
curl -fsSLo- https://raw.githubusercontent.com/samueleaton/sentry/crystal-v0.23.1/install.cr | crystal eval
```

This will install the Sentry CLI tool. To use the Crystal API, see [CRYSTAL_API.md](./CRYSTAL_API.md).

<p align="center">
  <img width="450" title="sentry" alt="sentry" src="https://raw.githubusercontent.com/samueleaton/design/master/sentry.gif" />
</p>

**Troubleshooting the install:** This install script is just a convenience. If it does not work, simply: (1) place the files located in the `src` dir into a your project in a `dev/` dir, and (2) compile sentry by doing `crystal build --release dev/sentry_cli.cr -o ./sentry`.

## Usage

Assuming `sentry.cr` was correctly placed in `[your project name]/dev/sentry.cr` and compiled into the root of your app as `sentry`, simply run:

```bash
./sentry [options]
```

### Options

#### Show Help Menu

```bash
./sentry --help
```

Example

```bash
$ ./sentry -h

Usage: ./sentry [options]
     -n NAME, --name=NAME             Sets the display name of the app process (default name: <your_app_here>)
     --src=PATH                       Sets the entry path for the main crystal file (default is inferred from shards.yaml)
     -b COMMAND, --build=COMMAND      Overrides the default build command (will override --src flag)
     --build-args=ARGS                Specifies arguments for the build command
     --no-build                       Skips the build step
     -r COMMAND, --run=COMMAND        Overrides the default run command
     --run-args=ARGS                  Specifies arguments for the run command
     -w FILE, --watch=FILE            Overrides default files and appends to list of watched files
     -c FILE, --config=FILE           Specifies a file to load for automatic configuration (default: '.sentry.yml')
     --install                        Run 'shards install' once before running Sentry build and run commands
     --no-color                       Removes colorization from output
     -i, --info                       Shows the values for build/run commands, build/run args, and watched files
     -h, --help                       Show this help
```

#### Override Default Build Command

```bash
./sentry -b "crystal build --release ./src/my_app.cr"
```

The default build command is `crystal build ./src/[app_name].cr`. The release flag is omitted by default for faster compilation time while you are developing.

#### Override Default Run Command

```bash
./sentry -r "./my_app"
```

The default run command is `./[app_name]`.

#### Override Default Files to Watch

```bash
./sentry -w "./src/**/*.cr" -w "./lib/**/*.cr"
```

The default files being watched are `["./src/**/*.cr", "./src/**/*.ecr"]`.

By specifying files to watch, the default will be omitted. So if you want to watch all of the file in your `src` directory, you will need to specify that like in the above example.

#### Show Info Before Running

This shows the values for the build command, run command, and watched files.

```bash
./sentry -i
```

Example

```
$ ./sentry -i

🤖  Sentry configuration:
       display name:   my_app
       shard name:     my_app
       install shards: true
       info:           true
       build:          crystal build ./src/my_app.cr
       build_args:     []
       run:            ./my_app
       run_args:       []
       watch:          ["./src/**/*.cr", "./src/**/*.ecr"]
🤖  Your SentryBot is vigilant. beep-boop...
...
...
```

#### Setting Build or Run Arguments

If you prefer granularity, you can specify arguments to the build or run commands using the `--build-args` or `--run-args` flags followed by a string of arguments.

```bash
./sentry -r "crystal" --run-args "spec --debug"
```

#### Running `shards install` Before Starting

This is especially usefull when initiating Sentry from a `Dockerfile` or `package.json` file. It guarantees all the shards are installed before running.

```bash
./sentry --install
```

#### Reading Configurations from a File

Sentry will automatically read configurations from `.sentry.yml` if it exists. This can be changed with `-c FILE` or `--config=FILE`.

See the `YAML.mapping` definition in the `Config` class in [the `/src/sentry.cr` file](src/sentry.cr) for valid file properties.

#### Removing Colorization

Sentry output is colorized by default. To remove colorization, pass the `--no-color` argument.

Example

```bash
./sentry --no-color
```

## Sentry Crystal API

See [CRYSTAL_API.md](./CRYSTAL_API.md)

## Why?

(1) It is tiring to have to stop and restart an app on every change.

(2) Docker!

Stop and restarting your app is especially expensive (and annoying) when running the app in a docker container, where one would need to totally rebuild the docker image for every change.

Now, for development, simply run sentry in your docker container, and it will rebuild the app from the docker container on any changes, without rebuilding the docker image/container.

## Contributing

1. Fork it ( https://github.com/samueleaton/sentry/fork )
2. Create your feature branch (git checkout -b feat-my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin feat-my-new-feature)
5. Create a new Pull Request

## Contributors

- [samueleaton](https://github.com/samueleaton) Sam Eaton - creator, maintainer

## Disclaimer

Sentry is intended for use in a development environment, where failure is safe and expected 😉.
