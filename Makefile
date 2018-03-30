

all:
	nim -d:release c nimwhistle.nim


cleantests:
	rm -f tests/basic
	rm -rf test/nimcache

tests: cleantests
	nim c --path:.. -r tests/basic.nim