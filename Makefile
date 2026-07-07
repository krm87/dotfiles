.PHONY: check doctor dry-run install

check:
	./bin/check

doctor:
	./bin/doctor

dry-run:
	./install.sh --dry-run

install:
	./install.sh
