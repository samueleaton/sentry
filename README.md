# Sentry 🤖  

Build/Runs your crystal application, watches files, and rebuilds/reruns app on file changes

## Installation

To install in you project, from the root directory of your project, run:
```bash
curl -fsSLo- https://raw.githubusercontent.com/samueleaton/sentry/master/install.rb | ruby
```

This install script is just a convenience. If it does not work, simply place the file located at `src/sentry.cr` into a your project at `dev/sentry.cr`.

## Usage

Assuming `sentry.cr` was correctly placed in `[your project name]/dev/sentry.cr`, simply run (from the root directory of your app):

```bash
crystal dev/sentry.cr
```

You can override the `build` and `run` commands by setting the `BUILD` and `RUN` environment variables, respectively:

```bash
BUILD="crystal build src/my_app.cr" RUN="POSTGRES_USER=postgres ./my_app" crystal dev/sentry.cr
```

## Why?

Docker.

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
