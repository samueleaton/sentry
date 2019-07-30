all:

install: ../../bin/sentry

../../bin/sentry: bin/sentry ../../bin
	cp bin/sentry ../../bin/

../../bin:
	mkdir -p ../../bin

bin/sentry:
	shards build --release sentry

.PHONY: all install bin/sentry
