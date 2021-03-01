$ git clone -b firefox-78-wip https://github.com/webdino/meta-browser.git
$ git clone https://github.com/meta-rust/meta-rust.git
$ git -C meta-rust checkout be88d857a6ba9134abb795b3a34d3a839196335f
$ git clone -b rocko-again https://github.com/webdino/meta-clang.git
$ git clone --branch esr78 --depth 1 https://github.com/mozilla/gecko-dev.git
$ export SHELL
$ (cd gecko-dev && ./mach bootstrap --application-choice browser --no-interactive
https://github.com/renesas-rz/meta-rzg2.git
