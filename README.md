# Recursive Find and Replace Bash Script

A Bash script that recursively searches for files within a specified directory, finds all occurrences of a given text string within those files, replaces them with another string, and reports the changes.

## Features

* **Recursive Search**: Traverses all subdirectories.
* **In-Place Replacement**: Modifies files directly.
* **Occurrence Reporting**: Reports the number of replacements per file and a total summary.
* **Handles Special Characters**: Attempts to correctly handle special characters in search and replacement strings for `sed`.
* **Handles Filenames with Spaces**: Uses `find ... -print0` and `read -d $'\0'` for robust filename handling.
* **Text File Focus**: Attempts to process only text files using the `file` command and `grep text`.
* **Help Option**: Provides a detailed help message with `--help` or `-h`.

## Prerequisites

* A Bash shell (version 4.0+ recommended for associative arrays).
* Standard Unix/Linux command-line utilities:
  * `find`
  * `grep`
  * `sed`
  * `wc`
  * `file`
  * `cmp`
  * `mv`
  * `mktemp`
  * `sort`
  * `printf`

These are typically available on most Linux distributions and macOS.

## Installation

1. Download the `replacer.sh` script.
2. Make it executable:
```bash
chmod +x replacer.sh
```

## Usage

```bash
./replacer.sh <text_to_find> <text_to_replace_with> <directory>
```

### Arguments

* `<text_to_find>`: The exact text string you want to search for and replace. This is case-sensitive. If the string contains spaces, enclose it in quotes.
* `<text_to_replace_with>`: The text string that will replace all occurrences of <text_to_find>`. If the string contains spaces, enclose it in quotes.
* `<directory>`: The path to the root directory where the script will start its recursive search.

### Options

* `--help`, `-h`: Display the help message with detailed usage instructions and exit.

## Example

To replace all occurrences of "Project Alpha" with "Project Omega" in all files within the `./project_files` directory and its subdirectories:

```bash
./replacer.sh "Project Alpha" "Project Omega" ./project_files
```

## 🚨 Important Warning 🚨

**This script modifies files directly (in-place). There is no undo feature.**

**ALWAYS BACKUP YOUR DIRECTORY AND FILES BEFORE RUNNING THIS SCRIPT, especially when working with important data.** Test the script on a sample directory first to ensure it behaves as expected.

## How It Works

1. **Input Validation**: Checks for the correct number of arguments, if the search text is provided, and if the target directory exists.
2. **File Discovery**: Uses `find` to locate all regular files within the specified directory hierarchy.
3. **Text File Filtering**: For each found file, it uses the `file` command and `grep` to make a basic attempt to identify if it's a text file. Binary files are generally skipped.
4. **Occurrence Counting**: If a file is deemed a text file, `grep -oF` is used to count the occurrences of `<text_to_find>` before any modification.
5. **Safe Replacement**:
* If occurrences are found, the script escapes special characters in the search and replacement strings to be safely used with `sed`.
* `sed` performs the substitution, writing the output to a temporary file.
* `cmp` compares the temporary file with the original. If they differ (meaning a change was made), the temporary file is moved to replace the original file. This approach is generally safer than `sed -i` directly, especially for cross-platform compatibility and atomicity.
6. **Reporting**: The script keeps track of modified files and the number of replacements. After processing all files, it prints a summary report.

## Contributing

Contributions, bug reports, and feature requests are welcome! Please feel free to open an issue or submit a pull request.

## License

This project is published under the [MIT License](LICENSE).
