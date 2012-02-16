build:
	mkdir -p lib && coffee -c -o lib src

test:
	./node_modules/.bin/_mocha --reporter spec

clean:
	rm -r lib

dev:
	coffee -wc --bare -o lib src

.PHONY: test
