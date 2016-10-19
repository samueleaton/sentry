# Sentry 🤖  

Build/Runs your crystal application, watches files, and rebuilds/reruns app on file changes

## Installation

To install in your project, from the root directory of your project, run:
```bash
curl -fsSLo- https://raw.githubusercontent.com/samueleaton/sentry/master/install.rb | ruby
```

This install script is just a convenience. If it does not work, simply: (1) place the file located at `src/sentry.cr` into a your project at `dev/sentry.cr`, (2) replace any instances of `[app_name]` with your app name, and (3) compile sentry by doing `crystal dev/sentry.cr -o ./sentry`.

<p align="center">
  <img width="450" title="sentry" alt="sentry" src="https://raw.githubusercontent.com/samueleaton/design/master/sentry.gif" />
</p>

## Usage

Assuming `sentry.cr` was correctly placed in `[your project name]/dev/sentry.cr`, simply run (from the root directory of your app):

```bash
crystal dev/sentry.cr
```

### Options

#### Show Help Menu

```bash
./sentry --help
```

#### Override Default Build Command

```bash
./sentry -b "crystal build --release ./src/my_app.cr"
```

The default build command is `crystal build ./src/[app_name].cr`.

#### Override Default Run Command

```bash
./sentry -r "./my_app"
```

The default run command is `./[app_name]`.

#### Override Default Files to Watch

```bash
./sentry -w "./src/**/*.cr" -w "./lib/**/*.cr"
```

The default files being watched are `["./src/**/*.cr"]`.

By specifying files to watch, the default will be omitted.

#### Show Info Before Running

This shows the values for the build command, run command, and watched files.

```bash
./sentry -i
```

Example  
```
$ ./sentry -i

  build:  crystal build ./src/my_app.cr
  run:  ./my_app
  files:  ["./src/**/*.cr"]

🤖  sentry is vigilant. beep-boop...
...
...
```

## Why?

Docker, mainly.

It is tiring to have to stop and restart an app on every change. This becomes especially annoying when running the app in a docker container, where one would need to totally rebuild the docker image for every change.

Now, for development, simply run sentry in your docker container, and it will rebuild the app from the docker container on any changes, without rebuilding the docker image/container.

If you aren't using docker, no biggie, it still works.

## Contributing

1. Fork it ( https://github.com/samueleaton/sentry/fork )
2. Create your feature branch (git checkout -b feat/my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin feat/my-new-feature)
5. Create a new Pull Request

## Contributors

- [samueleaton](https://github.com/samueleaton) Sam Eaton - creator, maintainer

## Disclaimer

Sentry is intended for use in a development environment, where failure is safe and expected 😉.
