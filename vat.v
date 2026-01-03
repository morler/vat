module main

import printer
import vaterror
import os
import cli

const stdin_abbrev = '-'

const stdin_placeholder = '__STDIN__'

fn main() {
	// Handle stdin abbreviation '-' before cli parsing
	mut args_to_parse := [os.args[0]]  // Keep program name
	for arg in os.args[1..] {
		if arg == stdin_abbrev {
			args_to_parse << stdin_placeholder
		} else {
			args_to_parse << arg
		}
	}

	mut app := cli.Command{
		name: 'vat'
		description: 'vat is a simple clone of cat, written in V instead of C.\n' +
			'Written by Sebastian Schicho 2021.'
		usage: '\n\nConcatenate files to stdout with various formatting options.\n' +
			'Supports common cat flags: -n, -b, -E, -T, -v, -s, -A, -e, -t, -u'
		version: '0.2'
		execute: fn (cmd cli.Command) ! {
			mut opts := printer.PrintOptions{}
			found_flags := cmd.flags.get_all_found()
			for f in found_flags {
				match f.name {
					'number' { opts.number = true }
					'number-nonblank' {
						opts.number = true
						opts.number_nonblank = true
					}
					'show-ends' { opts.show_ends = true }
					'show-tabs' { opts.show_tabs = true }
					'show-nonprinting' { opts.show_nonprinting = true }
					'squeeze-blank' { opts.squeeze_blank = true }
					'show-all' {
						opts.show_nonprinting = true
						opts.show_ends = true
						opts.show_tabs = true
					}
					'show-nonprinting-ends' {
						opts.show_nonprinting = true
						opts.show_ends = true
					}
					'show-nonprinting-tabs' {
						opts.show_nonprinting = true
						opts.show_tabs = true
					}
					'ignored' {
						// -u flag is ignored (POSIX requirement, no effect)
					}
					else {}
				}
			}
			// Replace stdin placeholder back to '-'
			mut processed_args := []string{}
			for arg in cmd.args {
				if arg == stdin_placeholder {
					processed_args << stdin_abbrev
				} else {
					processed_args << arg
				}
			}
			run_vat(processed_args, opts)
			return
		}
		flags: [
			cli.Flag{ flag: cli.FlagType.bool, name: 'number', abbrev: 'n' }
			cli.Flag{ flag: cli.FlagType.bool, name: 'number-nonblank', abbrev: 'b' }
			cli.Flag{ flag: cli.FlagType.bool, name: 'show-ends', abbrev: 'E' }
			cli.Flag{ flag: cli.FlagType.bool, name: 'show-tabs', abbrev: 'T' }
			cli.Flag{ flag: cli.FlagType.bool, name: 'show-nonprinting', abbrev: 'v' }
			cli.Flag{ flag: cli.FlagType.bool, name: 'squeeze-blank', abbrev: 's' }
			cli.Flag{ flag: cli.FlagType.bool, name: 'show-all', abbrev: 'A' }
			cli.Flag{ flag: cli.FlagType.bool, name: 'show-nonprinting-ends', abbrev: 'e' }
			cli.Flag{ flag: cli.FlagType.bool, name: 'show-nonprinting-tabs', abbrev: 't' }
			cli.Flag{ flag: cli.FlagType.bool, name: 'ignored', abbrev: 'u' }
			cli.Flag{ flag: cli.FlagType.bool, name: 'help', abbrev: 'h' }
		]
	}
	app.setup()
	app.parse(args_to_parse)
}

fn run_vat(args []string, opts printer.PrintOptions) {
	has_formatting := opts.number || opts.number_nonblank || opts.show_ends ||
		opts.show_tabs || opts.show_nonprinting || opts.squeeze_blank

	if args.len == 0 {
		if has_formatting {
			mut lp := printer.new_line_printer('', opts)
			lp.print()
		} else {
			mut sp := printer.new_stdin_printer()
			sp.print()
		}
	} else {
		for arg in args {
			if arg == stdin_abbrev {
				if has_formatting {
					mut lp := printer.new_line_printer('', opts)
					lp.print()
				} else {
					mut sp := printer.new_stdin_printer()
					sp.print()
				}
			} else if !os.exists(arg) {
				vaterror.fatalln_file_error(arg, .not_exists)
			} else if os.is_dir(arg) {
				vaterror.fatalln_file_error(arg, .is_directory)
			} else {
				if has_formatting {
					mut lp := printer.new_line_printer(arg, opts)
					lp.print()
				} else {
					mut fp := printer.new_file_printer(arg)
					fp.print()
				}
			}
		}
	}
}
