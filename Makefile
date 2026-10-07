# ools Makefile
#
# Usage:
#   make build       - compile main.oo to dist/ools
#   make check       - run oodac check on every .oo file
#   make line-cap    - enforce 16-256 line cap on every .oo and .oot (shim-exempt)
#   make file-law    - reject forbidden file extensions and stray docs
#   make academy     - verify every .oo has the 4-element Academy header
#   make density     - enforce at most 8 pages per directory
#   make verify      - run line-cap, file-law, academy, density, and check
#   make test        - run functional test suite
#   make bench       - run performance benchmarks
#   make package-deb - generate Debian (.deb) package
#   make package-rpm - generate RedHat/Fedora (.rpm) package
#   make package-arch- generate Arch Linux (.pkg.tar.zst) package
#   make package     - build all distribution packages
#   make install     - install ools and ools-uninstall
#   make uninstall   - remove ools and ools-uninstall
#   make clean       - remove build artifacts

OODA_COMPILER ?= $(firstword $(wildcard $(HOME)/.openooda/bin/oodac $(CURDIR)/../../openOODA/oodac/bin/oodac))
OODACODEX ?= $(HOME)/.openooda/northstar.oot
OO_LIST_AMBIENT_QUOTA ?= 8589934592
BIN := dist/ools
VERSION ?= 0.2.0
PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin

SRC := $(wildcard *.oo) $(wildcard */*.oo)

.PHONY: all build check line-cap file-law academy density verify test bench install uninstall package package-deb package-rpm package-arch clean

all: verify build test

build: $(BIN)

$(BIN): $(SRC)
	@mkdir -p dist .ooda-cache/ooda-tmp
	OO_LIST_AMBIENT_QUOTA=$(OO_LIST_AMBIENT_QUOTA) OODACODEX=$(OODACODEX) OODA_COMPILER=$(OODA_COMPILER) OODA_NO_JAIL=1 $(OODA_COMPILER) build main.oo -o $(BIN)
	@chmod +x $(BIN)
	@cp -a $(BIN) dist/ools-linux-x86_64
	@sha256sum dist/ools-linux-x86_64 > dist/ools-linux-x86_64.sha256
	@echo "built $(BIN) (and dist/ools-linux-x86_64)"

# --- Verification gate ---------------------------------------------------------

line-cap:
	@violations=0; \
	for f in $$(find . -name "*.oo" -o -name "*.oot"); do \
		n=$$(wc -l < "$$f"); \
		if [ $$n -gt 256 ]; then \
			echo "VIOLATION: $$f = $$n lines (exceeds 256)"; violations=$$((violations+1)); \
			continue; \
		fi; \
		code=$$(grep -vE '^[[:space:]]*(//.*)?$$' "$$f" | grep -cvE '^[[:space:]]*import[[:space:]]+"'); \
		if [ "$$code" = "0" ]; then continue; fi; \
		if [ $$n -lt 16 ]; then \
			echo "VIOLATION: $$f = $$n lines (under 16-line floor, not a shim)"; violations=$$((violations+1)); \
			continue; \
		fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: $$violations files violate the Page Rule"; exit 1; fi; \
	echo "PASS: Page Rule sizing (16-256 lines, shims exempt from floor) holds"

file-law:
	@forbidden="py js ts rb pl json yaml toml"; \
	violations=0; \
	for ext in $$forbidden; do \
		found=$$(find . -name "*.$$ext" -not -path "./.git/*" -not -path "./.github/*" -not -path "./dist/*" -not -path "./.ooda-cache/*" -not -path "./.blackbox/*" 2>/dev/null | head -3); \
		if [ -n "$$found" ]; then \
			echo "VIOLATION: .$$ext forbidden:"; echo "$$found"; violations=$$((violations+1)); \
		fi; \
	done; \
	for f in $$(find . -name "*.md" -not -path "./.git/*" -not -path "./.github/*" -not -path "./dist/*" -not -path "./.ooda-cache/*" 2>/dev/null); do \
		if [ "$$f" != "./README.md" ] && [ "$$f" != "./AGENTS.md" ]; then \
			echo "VIOLATION: .md forbidden outside README.md and AGENTS.md: $$f"; violations=$$((violations+1)); \
		fi; \
	done; \
	for f in $$(find . -name "*.sh" -not -path "./.git/*" -not -path "./dist/*" 2>/dev/null); do \
		if [ "$$f" != "./install.sh" ] && [ "$$f" != "./uninstall.sh" ]; then \
			echo "VIOLATION: .sh forbidden outside install.sh and uninstall.sh: $$f"; violations=$$((violations+1)); \
		fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: file-law violations"; exit 1; fi; \
	echo "PASS: file law holds"

academy:
	@failures=0; \
	for f in $$(find . -name "*.oo" -not -path "./dist/*"); do \
		header=$$(head -7 "$$f"); \
		missing=""; \
		echo "$$header" | grep -q "^// # "        || missing="$$missing title"; \
		echo "$$header" | grep -q "^// Logline:"  || missing="$$missing logline"; \
		echo "$$header" | grep -q "^// Setup:"    || missing="$$missing setup"; \
		echo "$$header" | grep -q "^// Beats:"    || missing="$$missing beats"; \
		if [ -n "$$missing" ]; then \
			echo "FAIL: $$f missing Academy element(s):$$missing"; failures=$$((failures+1)); \
		fi; \
	done; \
	if [ $$failures -gt 0 ]; then echo "FAIL: $$failures academy header violations"; exit 1; fi; \
	echo "PASS: academy headers hold (all 4 elements present in first 7 lines)"

density:
	@violations=0; \
	for d in $$(find . -type d -not -path "./.git*" -not -path "./dist*" -not -path "./.ooda-cache*" -not -path "./packaging*" -not -path "./qa*"); do \
		n=$$(ls "$$d"/*.oo "$$d"/*.oot 2>/dev/null | grep -v '\*' | wc -l); \
		if [ $$n -gt 8 ]; then \
			echo "VIOLATION: $$d holds $$n pages (exceeds 8)"; violations=$$((violations+1)); \
		fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: $$violations directories exceed the density bound"; exit 1; fi; \
	echo "PASS: directory density (<= 8 pages per directory) holds"

check:
	@for f in $$(find . -name "*.oo" -not -path "./dist/*"); do \
		$(OODA_COMPILER) check "$$f" > /dev/null || exit 1; \
	done; \
	echo "PASS: oodac check holds on all .oo files"

verify: line-cap file-law academy density check

test: $(BIN)
	@echo "=== Tier 1: Core CLI & Listing Layouts ==="
	@./$(BIN) --help > /dev/null && echo "PASS: --help"
	@./$(BIN) --version | grep -q "0.2.0" && echo "PASS: --version"
	@./$(BIN) -1 qa/fixtures | grep -q "alpha.txt" && echo "PASS: -1 single column"
	@./$(BIN) -l qa/fixtures | grep -q "alpha.txt" && echo "PASS: -l long format"
	@./$(BIN) -lh qa/fixtures | grep -q "alpha.txt" && echo "PASS: -lh human-readable sizes"
	@test "$$(./$(BIN) -1 qa/fixtures | head -n 1)" != "$$(./$(BIN) -1 -r qa/fixtures | head -n 1)" && echo "PASS: -r reverse ordering"
	@./$(BIN) -1 -X qa/fixtures | head -n 1 | grep -q "alpha_link" && echo "PASS: -X sort by extension"
	@./$(BIN) -1 -R qa/fixtures | grep -q "sub/child.txt" && echo "PASS: -R recursive listing"
	@./$(BIN) -1 -a qa/fixtures | grep -q "\.hidden\.txt" && echo "PASS: -a includes hidden files"
	@./$(BIN) -1 -A qa/fixtures | grep -q "\.hidden\.txt" && echo "PASS: -A includes hidden files without . and .."
	@test "$$(./$(BIN) -1 -A qa/fixtures | grep -E '^\.\.?$$' | wc -l)" = "0" && echo "PASS: -A excludes . and .."
	@./$(BIN) -d qa/fixtures | grep -q "qa/fixtures" && echo "PASS: -d directory only"
	@./$(BIN) -F qa/fixtures | grep -q "alpha_link@" && echo "PASS: -F classify symlink indicator @"
	@./$(BIN) -F qa/fixtures | grep -q "sub/" && echo "PASS: -F classify directory indicator /"
	@./$(BIN) --json qa/fixtures | grep -q '"name":"alpha.txt"' && echo "PASS: --json formatted JSON Lines"
	@echo "=== Tier 2: Boundary & Negative Trust ==="
	@./$(BIN) --invalid-xyz > /dev/null 2>&1; test $$? -eq 2 && echo "PASS: invalid flag exits 2"
	@./$(BIN) /nonexistent/file/path/xyz > /dev/null 2>&1; test $$? -eq 2 && echo "PASS: nonexistent path exits 2"
	@./$(BIN) -1 qa/fixtures/empty.txt | grep -q "empty.txt" && echo "PASS: empty file handled"
	@./$(BIN) -l qa/fixtures/empty.txt | grep -q "0" && echo "PASS: empty file 0 size"
	@./$(BIN) -1 qa/fixtures | grep -qv "\.hidden\.txt" && echo "PASS: default ignores hidden files"
	@./$(BIN) -l qa/fixtures | grep "alpha_link" | grep -q "lrwxrwxrwx" && echo "PASS: symlink lrwxrwxrwx mode"
	@ln -sf nonexistent_target qa/fixtures/broken_probe && ./$(BIN) --color=never -l qa/fixtures | grep -F -q "broken_probe -> [broken]" && rm -f qa/fixtures/broken_probe && echo "PASS: broken symlink rendered as -> [broken]"
	@OO_COLUMNS=30 ./$(BIN) --color=never qa/fixtures | grep -q "^alpha.txt$$" && echo "PASS: narrow terminal OO_COLUMNS < 40 collapses to single column"
	@./$(BIN) -1 qa/fixtures/sub | grep -q "child.txt" && echo "PASS: subdirectory path inspected"
	@echo "=== Tier 3: Combinations & Color Controls ==="
	@./$(BIN) -la qa/fixtures | grep -q "\.hidden\.txt" && echo "PASS: combined -la flags"
	@./$(BIN) -lah qa/fixtures | grep -q "\.hidden\.txt" && echo "PASS: combined -lah flags"
	@./$(BIN) -lA qa/fixtures | grep -q "\.hidden\.txt" && echo "PASS: combined -lA flags"
	@./$(BIN) -1r qa/fixtures | head -n 1 | grep -q "sub" && echo "PASS: combined -1r flags"
	@./$(BIN) --color=always qa/fixtures | grep -q "$$(printf '\033')" && echo "PASS: --color=always injects ANSI escapes"
	@test -z "$$(./$(BIN) --color=never qa/fixtures | grep "$$(printf '\033')")" && echo "PASS: --color=never suppresses ANSI escapes"
	@./$(BIN) -1 qa/fixtures/alpha.txt qa/fixtures/beta.txt | grep -q "alpha.txt" && echo "PASS: multi-argument paths"
	@./$(BIN) -1 -- qa/fixtures/alpha.txt | grep -q "alpha.txt" && echo "PASS: -- double dash delimiter"
	@echo "=== Tier 4: MCP Protocol & Introspection ==="
	@printf '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}\n' | ./$(BIN) --mcp | grep -q "2024-11-05" && echo "PASS: MCP initialize"
	@printf '{"jsonrpc":"2.0","id":2,"method":"ping","params":{}}\n' | ./$(BIN) --mcp | grep -q '"result":{}' && echo "PASS: MCP ping"
	@printf '{"jsonrpc":"2.0","id":3,"method":"tools/list","params":{}}\n' | ./$(BIN) --mcp | grep -q "list_directory" && echo "PASS: MCP tools/list list_directory"
	@printf '{"jsonrpc":"2.0","id":4,"method":"tools/list","params":{}}\n' | ./$(BIN) --mcp | grep -q "stat_entry" && echo "PASS: MCP tools/list stat_entry"
	@printf '{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"list_directory","arguments":{"path":"qa/fixtures","detail_level":"compact"}}}\n' | ./$(BIN) --mcp | grep -q "alpha.txt" && echo "PASS: MCP tools/call list_directory compact"
	@printf '{"jsonrpc":"2.0","id":6,"method":"tools/call","params":{"name":"list_directory","arguments":{"path":"qa/fixtures","detail_level":"json"}}}\n' | ./$(BIN) --mcp | grep -q "alpha.txt" && echo "PASS: MCP tools/call list_directory json"
	@printf '{"jsonrpc":"2.0","id":7,"method":"tools/call","params":{"name":"list_directory","arguments":{"path":"qa/fixtures","detail_level":"detailed"}}}\n' | ./$(BIN) --mcp | grep -q "alpha.txt" && echo "PASS: MCP tools/call list_directory detailed"
	@printf '{"jsonrpc":"2.0","id":8,"method":"tools/call","params":{"name":"stat_entry","arguments":{"path":"qa/fixtures/alpha.txt"}}}\n' | ./$(BIN) --mcp | grep -q "qa/fixtures/alpha.txt" && echo "PASS: MCP tools/call stat_entry"
	@printf '{"jsonrpc":"2.0","id":9,"method":"tools/call","params":{"name":"nonexistent_tool","arguments":{}}}\n' | ./$(BIN) --mcp | grep -q -- "-32601" && echo "PASS: MCP unknown tool exits -32601"
	@printf '{"jsonrpc":"2.0","id":10,"method":"tools/call","params":{"name":"stat_entry","arguments":{}}}\n' | ./$(BIN) --mcp | grep -q -- "-32602" && echo "PASS: MCP missing path exits -32602"
	@printf '{"jsonrpc":"2.0","id":11,"method":"tools/call","params":{"name":"stat_entry","arguments":{"path":"/nonexistent/bad/path"}}}\n' | ./$(BIN) --mcp | grep -q -- "-32602" && echo "PASS: MCP bad path exits -32602"
	@printf '{"jsonrpc":"2.0","id":12,"method":"tools/call","params":{"name":"list_directory","arguments":{"path":"qa/fixtures","recursive":true,"detail_level":"compact"}}}\n' | ./$(BIN) --mcp | grep -q "sub/child.txt" && echo "PASS: MCP tools/call list_directory recursive"
	@printf '{"jsonrpc":"2.0","id":13,"method":"tools/call","params":{"name":"list_directory","arguments":{"path":"qa/fixtures","sort_by":"extension","detail_level":"compact"}}}\n' | ./$(BIN) --mcp | grep -q "alpha_link" && echo "PASS: MCP tools/call list_directory sort_by extension"
	@printf 'invalid json payload\n' | ./$(BIN) --mcp | grep -q -- "-32600" && echo "PASS: MCP invalid payload exits -32600"
	@test "$$(printf '{"jsonrpc":"2.0","id":1,"method":"ping","params":{}}{"jsonrpc":"2.0","id":2,"method":"ping","params":{}}\n' | ./$(BIN) --mcp | grep -c '"result":{}')" = "2" && echo "PASS: MCP back-to-back requests without newline delimiters"
	@printf '{"jsonrpc":"2.0","id":99,"method":"ping","params":{}}' | ./$(BIN) --mcp | grep -q '"id":99' && echo "PASS: MCP request without trailing newline"
	@test -z "$$(printf '{"jsonrpc":"2.0","method":"notifications/initialized","params":{}}\n' | ./$(BIN) --mcp)" && echo "PASS: MCP notifications/initialized produces no response"
	@printf '{"jsonrpc":"2.0","id":14,"method":"shutdown","params":{}}\n' | ./$(BIN) --mcp | grep -q '"result":null' && echo "PASS: MCP shutdown"
	@test -z "$$(printf '{"jsonrpc":"2.0","method":"exit","params":{}}\n' | ./$(BIN) --mcp)" && echo "PASS: MCP exit terminates cleanly"
	@(sleep 0.2 && printf '{"jsonrpc":"2.0","id":15,"method":"ping","params":{}}\n') | ./$(BIN) --mcp | grep -q '"result":{}' && echo "PASS: MCP stdio idle pause does not crash server"
	@printf '{"id":"method","method":"ping","params":{}}\n' | ./$(BIN) --mcp | grep -q '"id":"method"' && echo "PASS: MCP string value matching key name parses correctly"
	@echo "=== Determinism Probe ==="
	@run1="$$(./$(BIN) -1 qa/fixtures)"; \
	run2="$$(./$(BIN) -1 qa/fixtures)"; \
	test "$$run1" = "$$run2" && echo "PASS: determinism Run_1 == Run_2"
	@echo "=== Packaging & Installer Smoke Tests ==="
	@./install.sh --dry-run > /dev/null && echo "PASS: install.sh --dry-run"
	@./install.sh --uninstall --dry-run > /dev/null && echo "PASS: install.sh --uninstall --dry-run"
	@./uninstall.sh --dry-run > /dev/null && echo "PASS: uninstall.sh --dry-run"
	@echo "ALL TESTS PASSED"

bench: $(BIN)
	@echo "=== Running ools performance benchmarks ==="
	@echo "--- Listing repository root directory ---"
	@time -p ./$(BIN) -l . > /dev/null
	@echo "--- JSON export of repository root ---"
	@time -p ./$(BIN) --json . > /dev/null
	@echo "Benchmark complete."

install: $(BIN)
	@mkdir -p $(DESTDIR)$(BINDIR)
	install -m 0755 $(BIN) $(DESTDIR)$(BINDIR)/ools
	install -m 0755 uninstall.sh $(DESTDIR)$(BINDIR)/ools-uninstall
	@echo "installed ools and ools-uninstall to $(DESTDIR)$(BINDIR)"

uninstall:
	@rm -f $(DESTDIR)$(BINDIR)/ools $(DESTDIR)$(BINDIR)/ools-uninstall /usr/local/bin/ools /usr/local/bin/ools-uninstall /usr/bin/ools /usr/bin/ools-uninstall
	@rm -rf $(HOME)/.cache/ools $(HOME)/.config/ools
	@echo "uninstalled ools and ools-uninstall"

package-deb: $(BIN)
	@mkdir -p dist/deb-root/DEBIAN dist/deb-root/usr/bin
	@sed "s/^Version:.*/Version: $(VERSION)-1/" packaging/debian/control.binary > dist/deb-root/DEBIAN/control
	@cp $(BIN) dist/deb-root/usr/bin/ools
	@chmod 0755 dist/deb-root/usr/bin/ools
	@cp uninstall.sh dist/deb-root/usr/bin/ools-uninstall
	@chmod 0755 dist/deb-root/usr/bin/ools-uninstall
	@dpkg-deb --build --root-owner-group dist/deb-root dist/ools_$(VERSION)-1_amd64.deb
	@rm -rf dist/deb-root
	@echo "built dist/ools_$(VERSION)-1_amd64.deb"

package-rpm: $(BIN)
	@mkdir -p ~/rpmbuild/SOURCES ~/rpmbuild/SPECS ~/rpmbuild/RPMS
	@cp $(BIN) ~/rpmbuild/SOURCES/ools-linux-x86_64
	@cp uninstall.sh ~/rpmbuild/SOURCES/uninstall.sh
	@sed "s/^Version:.*/Version: $(VERSION)/" packaging/ools.spec > ~/rpmbuild/SPECS/ools.spec
	@rpmbuild -bb ~/rpmbuild/SPECS/ools.spec
	@cp ~/rpmbuild/RPMS/x86_64/ools-$(VERSION)*.rpm dist/
	@echo "built dist RPM package"

package-arch: $(BIN)
	@mkdir -p dist/arch-pkg/usr/bin
	@cp $(BIN) dist/arch-pkg/usr/bin/ools
	@chmod 0755 dist/arch-pkg/usr/bin/ools
	@cp uninstall.sh dist/arch-pkg/usr/bin/ools-uninstall
	@chmod 0755 dist/arch-pkg/usr/bin/ools-uninstall
	@printf "pkgname = ools\npkgbase = ools\npkgver = $(VERSION)-1\npkgdesc = Sovereign directory lister and metadata classifier with oote palettes and MCP surface\nurl = https://github.com/openOODA-tools/ools\nbuilddate = $$(date +%s)\npackager = openOODA-tools <ops@openooda.org>\nsize = $$(stat -c %s $(BIN))\narch = x86_64\nlicense = Apache-2.0\ndepend = glibc\nprovides = ools\n" > dist/arch-pkg/.PKGINFO
	@tar --zstd -cf dist/ools-$(VERSION)-1-x86_64.pkg.tar.zst -C dist/arch-pkg .PKGINFO usr
	@rm -rf dist/arch-pkg
	@bash -n packaging/arch/PKGBUILD
	@cp packaging/arch/PKGBUILD packaging/PKGBUILD
	@echo "built dist/ools-$(VERSION)-1-x86_64.pkg.tar.zst and validated PKGBUILD"

package: package-deb package-rpm package-arch

clean:
	@rm -rf dist .ooda-cache .blackbox
	@echo "cleaned"
