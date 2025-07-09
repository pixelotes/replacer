#!/bin/bash

# --- Recursive Text Replacement Tool ---

display_help() {
    echo "Recursively finds and replaces text in files within a specified directory."
    echo ""
    echo "Usage: $0 [OPTIONS] <text_to_find> <text_to_replace_with> <directory>"
    echo ""
    echo "Arguments:"
    echo "  <text_to_find>         The text string to be replaced."
    echo "  <text_to_replace_with> The text string to replace occurrences with."
    echo "  <directory>            The path to the directory to search within."
    echo ""
    echo "Options:"
    echo "  --help, -h             Display this help message and exit."
    echo "  --dry-run              Show what would be changed but make no actual changes."
    echo "  --backup               Create .bak backup of modified files."
    echo "  --ext=ext1,ext2        Restrict processing to files with specific extensions."
    echo "  --ignore-case          Perform case-insensitive matching."
    echo "  --log=FILE             Log output to the specified file."
    echo "  --debug                Show matching lines with highlighting (implies dry-run)."
    echo ""
    echo "Example:"
    echo "  $0 --dry-run --ext=txt,md \"OldText\" \"NewText\" ./docs"
    exit 0
}

# --- Default Flags ---
DRY_RUN=false
IGNORE_CASE=false
BACKUP=false
DEBUG=false
EXT_FILTER=()
LOG_FILE=""

# --- Parse Options ---
POSITIONAL=()
for arg in "$@"; do
    case $arg in
        --dry-run) DRY_RUN=true; shift ;;
        --ignore-case) IGNORE_CASE=true; shift ;;
        --backup) BACKUP=true; shift ;;
        --debug) DEBUG=true; DRY_RUN=true; shift ;;  # debug implies dry-run
        --ext=*) IFS=',' read -ra EXT_FILTER <<< "${arg#*=}"; shift ;;
        --log=*) LOG_FILE="${arg#*=}"; shift ;;
        --help|-h) display_help ;;
        -*)
            echo "Unknown option: $arg"
            exit 1
            ;;
        *) POSITIONAL+=("$arg") ;;
    esac
done
set -- "${POSITIONAL[@]}"

# --- Validate Arguments ---
if [ "$#" -ne 3 ]; then
    echo "Error: Incorrect number of arguments."
    echo "Run '$0 --help' for usage information."
    exit 1
fi

OLD_TEXT="$1"
NEW_TEXT="$2"
TARGET_DIRECTORY="$3"

if [ ! -d "$TARGET_DIRECTORY" ]; then
    echo "Error: Directory '$TARGET_DIRECTORY' not found."
    exit 1
fi

if [ -z "$OLD_TEXT" ]; then
    echo "Error: 'Text to find' cannot be empty."
    exit 1
fi

# --- Logging ---
if [ -n "$LOG_FILE" ]; then
    exec > >(tee -a "$LOG_FILE") 2>&1
fi

# --- Summary ---
echo "--- Recursive Text Replacement Tool ---"
echo "Directory:              $TARGET_DIRECTORY"
echo "Text to find:           '$OLD_TEXT'"
echo "Replacing with:         '$NEW_TEXT'"
echo "Dry run:                $DRY_RUN"
echo "Case-insensitive:       $IGNORE_CASE"
echo "Backup originals:       $BACKUP"
echo "Extension filter:       ${EXT_FILTER[*]:-(none)}"
echo "Debug mode:             $DEBUG"
echo "---------------------------------------"
echo

total_files_changed=0
total_occurrences_replaced=0

# --- Main File Loop ---
while IFS= read -r -d $'\0' file_path; do
    # --- Text File Check via MIME ---
    mime_type=$(file --mime-type -b "$file_path")
    case "$mime_type" in
        text/*|application/json|application/xml|application/javascript)
            # --- Extension Filtering ---
            if [ "${#EXT_FILTER[@]}" -gt 0 ]; then
                ext="${file_path##*.}"
                match=false
                for allowed_ext in "${EXT_FILTER[@]}"; do
                    if [[ "$ext" == "$allowed_ext" ]]; then
                        match=true
                        break
                    fi
                done
                [ "$match" == false ] && continue
            fi

            # --- Count Matches ---
            grep_opts="-oF"
            $IGNORE_CASE && grep_opts="-oiF"
            occurrences=$(grep $grep_opts -- "$OLD_TEXT" "$file_path" 2>/dev/null | wc -l)

            if [ "$occurrences" -gt 0 ]; then
                echo "Processing: $file_path"

                # --- Debug Output ---
                if $DEBUG; then
                    echo "  -- Matches found in:"
                    debug_grep_opts="-nF"
                    $IGNORE_CASE && debug_grep_opts="-niF"
                    grep $debug_grep_opts -- "$OLD_TEXT" "$file_path" | while IFS=: read -r lineno line; do
                        HIGHLIGHTED_LINE="${line//$OLD_TEXT/$'\e[7m'$OLD_TEXT$'\e[0m'}"
                        printf "     Line %s: %b\n" "$lineno" "$HIGHLIGHTED_LINE"
                    done
                fi

                # --- Prepare Replacement ---
                escaped_old_text=$(printf '%s\n' "$OLD_TEXT" | sed 's:[][\\/.^$*+?|():{}]:\\&:g')
                escaped_new_text=$(printf '%s\n' "$NEW_TEXT" | sed 's:[][\\/.^$*+?|():{}]:\\&:g')
                sed_flags="g"
                $IGNORE_CASE && sed_flags+="I"
                sed_cmd="s|$escaped_old_text|$escaped_new_text|$sed_flags"

                if $DRY_RUN; then
                    echo "  -> Would replace $occurrences occurrence(s)"
                else
                    tmp_file=$(mktemp)
                    if LC_ALL=C sed "$sed_cmd" "$file_path" > "$tmp_file" 2>/dev/null; then
                        if ! cmp -s "$tmp_file" "$file_path"; then
                            $BACKUP && cp "$file_path" "$file_path.bak"
                            if mv "$tmp_file" "$file_path"; then
                                total_files_changed=$((total_files_changed + 1))
                                total_occurrences_replaced=$((total_occurrences_replaced + occurrences))
                                echo "  -> Modified: $occurrences occurrence(s) replaced."
                            else
                                echo "  -> Error: Failed to move temporary file to '$file_path'."
                                rm -f "$tmp_file"
                            fi
                        else
                            echo "  -> No change needed (content already identical)"
                            rm -f "$tmp_file"
                        fi
                    else
                        echo "  -> Error: sed failed for '$file_path'"
                        rm -f "$tmp_file"
                    fi
                fi
            fi
            ;;
        *) continue ;;
    esac
done < <(find "$TARGET_DIRECTORY" -type f -print0)

# --- Summary Report ---
echo
echo "--- Replacement Report ---"
if [ "$total_files_changed" -gt 0 ]; then
    echo "Total files changed:         $total_files_changed"
    echo "Total occurrences replaced:  $total_occurrences_replaced"
else
    echo "No files were modified."
fi
echo "Script finished."
