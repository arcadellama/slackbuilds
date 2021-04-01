LIB_FOLDER=share/reddio
LIB_FILES=`find "$(LIB_FOLDER)" -type f 2>/dev/null`

PREFIX?=/usr/local

DOC_FOLDER=$(PREFIX)/share/doc/reddio

install:
	mkdir -p -- "$(PREFIX)/bin"
	cp reddio $(PREFIX)/bin/

	mkdir -p -- "$(PREFIX)/$(LIB_FOLDER)"
	for file in $(LIB_FILES); do cp -- "$$file" "$(PREFIX)/$$file"; done

	mkdir -p -- "$(DOC_FOLDER)"
	cp doc/* "$(DOC_FOLDER)"

uninstall:
	rm -- "$(PREFIX)/bin/reddio"

	for file in $(LIB_FILES); do rm -- "$(PREFIX)/$$file"; done
	rmdir -- "$(PREFIX)/$(LIB_FOLDER)" || :

	for file in doc/*; do rm -- "$(DOC_FOLDER)/$${file#*/}"; done
	rmdir -- "$(DOC_FOLDER)" || :

.PHONY: install uninstall
