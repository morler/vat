module printer

import os
import vaterror

struct StdinPrinter {}

pub fn new_stdin_printer() &StdinPrinter {
	return &StdinPrinter{}
}

pub fn (sp StdinPrinter) print() {
	mut stdout := os.stdout()
	file := os.stdin()

	mut buf := []u8{len: buf_size, cap: buf_size}

	for {
		nbytes := file.read(mut buf) or {
			break
		}
		if nbytes == 0 {
			break
		}
		stdout.write(buf[..nbytes]) or { vaterror.fatalln_file_error(stdout.str(), .cannot_write) }
	}
}
