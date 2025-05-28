#!/bin/bash

# --- Recursive Text Replacement Tool (Bash) ---

# Function to display help/usage
display_help() {
    echo "Recursively finds and replaces text in files within a specified directory."
    echo ""
    echo "Usage: $0 <directory> <text_to_find> <text_to_replace_with>"
    echo ""
    echo "Arguments:"
    echo "  <directory>              The path to the directory to search within."
    echo "  <text_to_find>         The text string to be replaced (case-sensitive)."
    echo "  <text_to_replace_with> The text string to replace occurrences with."
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

TARGET_DIRECTORY="$1"
OLD_TEXT="$2"
NEW_TEXT="$3"

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
find "$TARGET_DIRECTORY" -type f -print0 | while IFS= read -r -d $'\0' file_path; do
    # Check if the file is a text file (simple check, might need refinement for binary files)
    # and if it contains the OLD_TEXT (case-sensitive)
    if file "$file_path" | grep -q text; then
        # Count occurrences of OLD_TEXT before replacement
        # grep -o: prints only the matched (non-empty) parts of a matching line,
        #          with each such part on a separate output line.
        # wc -l: counts the number of lines, which corresponds to occurrences.
        # Using grep -F to treat OLD_TEXT as a fixed string, not a regex
        # Using -- to ensure OLD_TEXT isn't misinterpreted if it starts with -
        occurrences=$(grep -oF -- "$OLD_TEXT" "$file_path" 2>/dev/null | wc -l)

        if [ "$occurrences" -gt 0 ]; then
            echo "Processing: $file_path"
            # Perform the replacement using sed.
            # Escape OLD_TEXT and NEW_TEXT for sed.
            # This handles /, &, and other special characters in the search/replace strings.
            escaped_old_text=$(printf '%s\n' "$OLD_TEXT" | sed 's:[][\\/.^$*&]:\\&:g')
            escaped_new_text=$(printf '%s\n' "$NEW_TEXT" | sed 's:[][\\/.^$*&]:\\&:g')
            sed_command="s|$escaped_old_text|$escaped_new_text|g"

            # Create a temporary file for sed output
            tmp_file=$(mktemp)
            if sed "$sed_command" "$file_path" > "$tmp_file" 2>/dev/null; then
                # Verify if actual changes were made by comparing temp file with original
                if ! cmp -s "$tmp_file" "$file_path"; then
                    # Move the temporary file to the original file path
                    if mv "$tmp_file" "$file_path"; then
                        changed_files_report["$file_path"]=$occurrences
                        total_files_changed=$((total_files_changed + 1))
                        total_occurrences_replaced=$((total_occurrences_replaced + occurrences))
                        echo "  -> Modified: $occurrences occurrence(s) replaced."
                    else
                        echo "  -> Error: Failed to move temporary file to '$file_path'."
                        rm -f "$tmp_file" # Clean up temp file on error
                    fi
                else
                    echo "  -> No actual change needed (content would be identical)."
                    rm -f "$tmp_file" # Clean up temp file
                fi
            else
                echo "  -> Error: sed command failed for '$file_path'. Check for special characters or permissions."
                rm -f "$tmp_file" # Clean up temp file on error
            fi
        fi
    else
        # Silently skipping binary or non-text files unless verbose mode is added
        # echo "Skipping binary or non-text file: $file_path"
        : # No-op, placeholder for potential future logging
    fi
done

echo # Newline for readability
echo "--- Replacement Report ---"
if [ "$total_files_changed" -gt 0 ]; then
    # Sort the report by filepath for consistent output
    mapfile -t sorted_files < <(for k in "${!changed_files_report[@]}"; do echo "$k"; done | sort)

    for file_path in "${sorted_files[@]}"; do
        occurrences=${changed_files_report["$file_path"]}
        echo "- File: $file_path"
        echo "  Occurrences replaced: $occurrences"
    done
    echo "--------------------------"
    echo "Total files changed: $total_files_changed"
    echo "Total occurrences replaced: $total_occurrences_replaced"
else
    echo "No files were found containing the specified text, or no files needed changes."
fi
echo "--------------------------"
echo "Script finished."
