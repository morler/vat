module printer

import os
import vaterror

pub struct PrintOptions {
	pub mut:
		number           bool
		number_nonblank  bool
		show_ends        bool
		show_tabs        bool
		show_nonprinting bool
		squeeze_blank    bool
}

struct LinePrinter {
	filepath string
	opts     PrintOptions
}

pub fn new_line_printer(filepath string, opts PrintOptions) &LinePrinter {
	return &LinePrinter{filepath: filepath, opts: opts}
}

pub fn (mut lp LinePrinter) print() {
	mut stdout := os.stdout()

	if lp.filepath == '' {
		lp.process_stdin(mut stdout)
	} else {
		lp.process_file(mut stdout)
	}
}

fn (mut lp LinePrinter) process_file(mut stdout os.File) {
	mut file := os.open_file(lp.filepath, 'r') or {
		vaterror.fatalln_file_error(lp.filepath, .permission_denied)
		return
	}
	defer {
		file.close()
	}
	lp.process_reader(mut file, mut stdout)
}

fn (mut lp LinePrinter) process_stdin(mut stdout os.File) {
	lp.process_reader(mut os.stdin(), mut stdout)
}

fn (mut lp LinePrinter) process_reader(mut reader os.File, mut stdout os.File) {
	mut line_num := 1
	mut last_was_blank := false

	mut buf := []u8{len: 1024, cap: 1024}
	mut current_line := []u8{}

	for {
		nbytes := reader.read(mut buf) or {
			break
		}
		if nbytes == 0 {
			break
		}

		for i in 0 .. nbytes {
			ch := buf[i]
			if ch == `\n` {
				line_str := current_line.bytestr()
				increment_num := lp.print_processed_line(line_str, line_num, last_was_blank, mut stdout)
				current_line = []u8{}
				if increment_num {
					line_num++
				}
				last_was_blank = line_str == ''
			} else {
				current_line << ch
			}
		}
	}

	// Handle last line if exists
	if current_line.len > 0 {
		line_str := current_line.bytestr()
		lp.print_processed_line(line_str, line_num, last_was_blank, mut stdout)
	}
}

fn (mut lp LinePrinter) print_processed_line(line string, line_num int, last_was_blank bool, mut stdout os.File) bool {
	is_blank := line == ''

	if lp.opts.squeeze_blank && is_blank && last_was_blank {
		return false
	}

	output := if lp.opts.show_tabs || lp.opts.show_nonprinting {
		lp.process_chars(line)
	} else {
		line
	}

	mut result := []u8{}

	if lp.opts.number && (!lp.opts.number_nonblank || !is_blank) {
		num_str := line_num.str()
		// Right align to 6 chars
		for _ in 0 .. (6 - num_str.len) {
			result << ` `
		}
		result << num_str.bytes()
		result << `\t`
	}

	result << output.bytes()

	if lp.opts.show_ends {
		result << `$`
	}

	result << `\n`

	stdout.write(result) or {
		vaterror.fatalln_file_error(stdout.str(), .cannot_write)
	}

	// Increment line number only if line is numbered (non-blank or -n mode)
	return !is_blank || !lp.opts.number_nonblank
}

fn (mut lp LinePrinter) process_chars(s string) string {
	mut result := []u8{}

	for ch in s {
		if lp.opts.show_tabs && ch == `\t` {
			result << `^`
			result << `I`
		} else if lp.opts.show_nonprinting {
			if ch < 32 {
				result << `^`
				result << ch + 64
			} else if ch == 127 {
				result << `^`
				result << `?`
			} else if ch >= 128 {
				result << `M`
				result << `-`
				if ch >= 128 + 32 {
					result << ch - 128
				} else {
					result << `^`
					result << ch - 128 + 64
				}
			} else {
				result << ch
			}
		} else {
			result << ch
		}
	}

	return result.bytestr()
}
