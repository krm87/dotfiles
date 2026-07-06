.PHONY: check dry-run install

check:
	./bin/check

dry-run:
	./install.sh --dry-run

install:
	./install.sh
