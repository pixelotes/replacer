#!/bin/bash

# --- Recursive Text Replacement Tool (Bash) ---

# Function to display help/usage
display_help() {
    echo "Recursively finds and replaces text in files within a specified directory."
    echo ""
    echo "Usage: $0 <text_to_find> <text_to_replace_with> <directory>"
    echo ""
    echo "Arguments:"
    echo "  <text_to_find>         The text string to be replaced (case-sensitive)."
    echo "  <text_to_replace_with> The text string to replace occurrences with."
    echo "  <directory>              The path to the directory to search within."
    echo ""
    echo "Options:"
    echo "  --help, -h               Display this help message and exit."
    echo ""
    echo "Example:"
    echo "  $0 ./my_documents \"old project name\" \"new project name\""
    echo ""
    echo "Important Notes:"
    echo "  - This script modifies files in place. ALWAYS BACKUP YOUR DATA FIRST!"
    echo "  - Text matching is case-sensitive."
    echo "  - The script attempts to process only text files; binary files are usually skipped."
    echo "  - Ensure you have read/write permissions for the files and directory."
    exit 0
}

# Check for help request or no arguments
if [ "$#" -eq 0 ] || [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    display_help
fi

# Check if the correct number of operational arguments is provided
if [ "$#" -ne 3 ]; then
    echo "Error: Incorrect number of arguments."
    echo "Run '$0 --help' for usage information."
    exit 1
fi

OLD_TEXT="$1"
NEW_TEXT="$2"
TARGET_DIRECTORY="$3"

# Validate directory
if [ ! -d "$TARGET_DIRECTORY" ]; then
    echo "Error: Directory '$TARGET_DIRECTORY' not found."
    echo "Run '$0 --help' for usage information."
    exit 1
fi

# Validate old text (cannot be empty)
if [ -z "$OLD_TEXT" ]; then
    echo "Error: 'Text to find' cannot be empty."
    echo "Run '$0 --help' for usage information."
    exit 1
fi

echo "--- Recursive Text Replacement Tool ---"
echo "Directory:          $TARGET_DIRECTORY"
echo "Text to find:       '$OLD_TEXT'"
echo "Replacing with:     '$NEW_TEXT'"
echo "---------------------------------------"
echo # Newline for readability

# Prepare for reporting
declare -A changed_files_report # Associative array to store filename and count
total_files_changed=0
total_occurrences_replaced=0

# Use find to locate all regular files in the target directory and its subdirectories
# -print0 and read -r -d $'\0' handle filenames with spaces or special characters.
# Use a process substitution to avoid subshell, so variable changes persist
while IFS= read -r -d $'\0' file_path; do
    if file "$file_path" | grep -q text; then
        occurrences=$(grep -oF -- "$OLD_TEXT" "$file_path" 2>/dev/null | wc -l)
        if [ "$occurrences" -gt 0 ]; then
            echo "Processing: $file_path"
            escaped_old_text=$(printf '%s\n' "$OLD_TEXT" | sed 's:[][\\/.^$*&]:\\&:g')
            escaped_new_text=$(printf '%s\n' "$NEW_TEXT" | sed 's:[][\\/.^$*&]:\\&:g')
            sed_command="s|$escaped_old_text|$escaped_new_text|g"
            tmp_file=$(mktemp)
            if sed "$sed_command" "$file_path" > "$tmp_file" 2>/dev/null; then
                if ! cmp -s "$tmp_file" "$file_path"; then
                    if mv "$tmp_file" "$file_path"; then
                        changed_files_report["$file_path"]=$occurrences
                        total_files_changed=$((total_files_changed + 1))
                        total_occurrences_replaced=$((total_occurrences_replaced + occurrences))
                        echo "  -> Modified: $occurrences occurrence(s) replaced."
                    else
                        echo "  -> Error: Failed to move temporary file to '$file_path'."
                        rm -f "$tmp_file"
                    fi
                else
                    echo "  -> No actual change needed (content would be identical)."
                    rm -f "$tmp_file"
                fi
            else
                echo "  -> Error: sed command failed for '$file_path'. Check for special characters or permissions."
                rm -f "$tmp_file"
            fi
        fi
    else
        :
    fi
done < <(find "$TARGET_DIRECTORY" -type f -print0)

echo # Newline for readability
echo "--- Replacement Report ---"
if [ "$total_files_changed" -gt 0 ]; then
    echo "--------------------------"
    echo "Total files changed: $total_files_changed"
    echo "Total occurrences replaced: $total_occurrences_replaced"
else
    echo "--------------------------"
    echo "No files were found containing the specified text, or no files needed changes."
fi
echo "--------------------------"
echo "Script finished."

