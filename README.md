# vat

vat is a simple clone of cat, written in V instead of C.
It concatenates files to stdout with various formatting options.

The syntax is the same.

Supported flags:
- `-n, --number`: number all output lines
- `-b, --number-nonblank`: number non-blank output lines
- `-E, --show-ends`: display $ at end of each line
- `-T, --show-tabs`: display TAB characters as ^I
- `-v, --show-nonprinting`: use caret and M-notation
- `-s, --squeeze-blank`: suppress repeated empty output lines
- `-A, --show-all`: equivalent to -vET
- `-e, --show-nonprinting-ends`: equivalent to -vE
- `-t, --show-nonprinting-tabs`: equivalent to -vT
- `-u`: ignored (POSIX requirement)

This implementation is slightly slower than cat.
