test:
	./node_modules/.bin/_mocha --reporter spec

build:
	mkdir -p lib && coffee -c -o lib src

.PHONY: test
