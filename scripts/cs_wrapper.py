#!/usr/bin/env python3

import argparse
import sys
import subprocess


def main() -> int:
    parser = argparse.ArgumentParser(description="Ya Fast CodeSearch")
    parser.add_argument("--max", type=int, default=30, help="Max number of matches to report")
    parser.add_argument("--max-per-file", type=int, default=100, help="Max number of matches per file")
    parser.add_argument(
        "--current-folder", action="store_true", help="Restrict search to current folder with subfolders"
    )
    parser.add_argument("--whole-words", action="store_true", help="Match whole words only")
    parser.add_argument("--no-junk", action="store_true", help="Do not search in junk")
    parser.add_argument("--no-contrib", action="store_true", help="Do not search in contribs")
    parser.add_argument("regex", help="Regex to search")

    args = parser.parse_args()

    cli_command = ["ya", "tool", "cs", f"--max={args.max}", f"--max-per-file={args.max_per_file}"]

    if args.current_folder:
        cli_command.append("--current-folder")
    if args.whole_words:
        cli_command.append("--whole-words")
    if args.no_junk:
        cli_command.append("--no-junk")
    if args.no_contrib:
        cli_command.append("--no-contrib")

    cli_command.append("--")
    cli_command.append(args.regex)

    result = subprocess.check_output(cli_command, stderr=subprocess.DEVNULL)

    lines = parse_result(result)
    fixed_lines = fix_output_lines(lines, ars.current_folder)

    print('\n'.join(fixed_lines))

    return 0


def parse_result(cmd_result: str) -> list[str]:
    return cmd_result.decode(encoding="utf-8").strip().split("\n")


def fix_output_lines(lines: list[str], current_folder: bool) -> list[str]:
    split_sym = "\0"

    def line_fixer(line: str) -> str:
        tokens = line.split(":")

        file, line = tokens[0], tokens[1]
        content = ":".join(tokens[2:])

        if not current_folder:
            file = f'$(S)/{file}'

        return split_sym.join([file, line, "0", content])

    return list(map(line_fixer, lines))


if __name__ == "__main__":
    sys.exit(main())
