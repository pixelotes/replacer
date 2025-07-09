# Recursive Find and Replace Bash Script

A Bash script that recursively searches for files within a specified directory, finds all occurrences of a given text string within those files, replaces them with another string, and reports the changes.

## Features

* **Recursive Search**: Traverses all subdirectories.
* **In-Place Replacement**: Modifies files directly.
* **Occurrence Reporting**: Reports the number of replacements per file and a total summary.
* **Handles Special Characters**: Escapes search and replacement strings safely for use with `sed`.
* **Handles Filenames with Spaces**: Uses `find ... -print0` and `read -d $'\0'` for robust filename handling.
* **Text File Detection**: Uses `file --mime-type` to ensure only text files are processed.
* **Dry-Run Mode**: Preview the changes without modifying any files (`--dry-run`).
* **Backup Option**: Creates `.bak` backups of modified files (`--backup`).
* **Extension Filtering**: Restrict changes to files with specific extensions (`--ext=txt,md`).
* **Case-Insensitive Matching**: Replace text ignoring case (`--ignore-case`).
* **Debug Mode**: Shows matched lines with reverse-video highlighting (`--debug`).
* **Logging Support**: Outputs to a log file (`--log=path`).
* **Help Option**: Provides a detailed help message with `--help` or `-h`.

## Prerequisites

* A Bash shell (version 4.0+ recommended).
* Standard Unix/Linux command-line utilities:

  * `find`
  * `grep`
  * `sed`
  * `wc`
  * `file`
  * `cmp`
  * `mv`
  * `mktemp`
  * `printf`
  * `tee` (for logging)

These are typically available on most Linux distributions and macOS.

## Installation

1. Download the `replacer.sh` script.
2. Make it executable:

```bash
chmod +x replacer.sh
```

## Usage

```bash
./replacer.sh [OPTIONS] <text_to_find> <text_to_replace_with> <directory>
```

### Arguments

* `<text_to_find>`: The exact text string you want to search for and replace. Case-sensitive by default.
* `<text_to_replace_with>`: The text string that will replace all occurrences of `<text_to_find>`.
* `<directory>`: The path to the root directory where the script will start its recursive search.

### Options

* `--help`, `-h`: Display the help message and exit.
* `--dry-run`: Preview changes without modifying files.
* `--backup`: Save a `.bak` copy of each modified file.
* `--ext=ext1,ext2`: Only process files with the given extensions.
* `--ignore-case`: Match and replace text regardless of case.
* `--log=FILE`: Write the script output to a log file.
* `--debug`: Highlight matching lines in each file (implies `--dry-run`).

## Example

To replace all occurrences of "Project Alpha" with "Project Omega" in all `.txt` and `.md` files within the `./project_files` directory:

```bash
./replacer.sh --ext=txt,md --backup "Project Alpha" "Project Omega" ./project_files
```

To preview changes with line highlighting:

```bash
./replacer.sh --debug --ignore-case "apiKey" "API_KEY" ./src
```

## 🚨 Important Warning 🚨

**This script modifies files directly (in-place). There is no undo feature.**

**ALWAYS BACK UP YOUR FILES BEFORE RUNNING THIS SCRIPT.** Test on a sample directory to verify behavior first.

## How It Works

1. **Input Validation**: Ensures proper arguments and existence of the target directory.
2. **File Discovery**: Uses `find` to locate all regular files.
3. **Text File Filtering**: Uses `file --mime-type` to ensure the file is of a textual format (e.g. `text/plain`, `application/json`).
4. **Extension Filtering**: Optionally filters files based on extension.
5. **Match Counting**: Uses `grep -oF` (or `-oiF`) to count matches before replacing.
6. **Debug Preview**: In debug mode, prints matched lines with ANSI-highlighted matches.
7. **Safe Replacement**:

   * Escapes special characters in the search and replacement strings.
   * Uses `sed` (with optional case-insensitive flag) to perform replacements.
   * Writes changes to a temp file and compares it with the original.
   * If different, it optionally backs up the original and replaces it.
8. **Logging**: Optionally logs output to a file via `tee`.
9. **Summary Reporting**: Displays total files changed and occurrences replaced.

## Contributing

Contributions, bug reports, and feature requests are welcome! Please open an issue or submit a pull request.

## License

This project is published under the [MIT License](LICENSE).
