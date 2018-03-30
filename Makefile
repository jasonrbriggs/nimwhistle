

all:
	nim -d:release c nimwhistle.nim


cleantests:
	rm -f tests/basic
	rm -rf test/nimcache
	rm -f tests/website/nimwhistle.urls

tests: cleantests
	nim c --path:.. -r tests/basic.nim