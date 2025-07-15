#!/usr/bin/env bats

setup() {
  TMPDIR=$(mktemp -d)
  cp -r test/fixtures/* "$TMPDIR/"
}

teardown() {
  rm -rf "$TMPDIR"
}

###############
# OUTPUT TO LOG
###############

@test "replacer finds 3 occurrences of 'lumin'" {
    # Run the command with log output
    run ./replacer.sh --dry-run --log="$TMPDIR/test_output.log" lumin xxx "$TMPDIR"
    
    # Check that the command succeeded
    [ "$status" -eq 0 ]
    
    # Check the log file contains "3 occurrence(s)"
    grep -q "3 occurrence(s)" $TMPDIR/test_output.log
}

@test "replacer finds 4 occurrences of 'dolorem'" {
    # Run the command with log output
    run ./replacer.sh --dry-run --log="$TMPDIR/test_output.log" dolorem xxx "$TMPDIR"
    
    # Check that the command succeeded
    [ "$status" -eq 0 ]
    
    # Check the log file contains "4 occurrence(s)"
    grep -q "4 occurrence(s)" $TMPDIR/test_output.log
}

@test "replacer finds 5 occurrences of 'dolorem' with ignore-case" {
    # Run the command with log output and ignore-case flag
    run ./replacer.sh --dry-run --ignore-case --log="$TMPDIR/test_output.log" dolorem xxx test/fixtures/
    
    # Check that the command succeeded
    [ "$status" -eq 0 ]
    
    # Check the log file contains "5 occurrence(s)"
    grep -q "5 occurrence(s)" $TMPDIR/test_output.log
}

@test "replacer finds no files to modify for nonexisting text" {
    # Run the command with log output
    run ./replacer.sh --dry-run --log="$TMPDIR/test_output.log" nonexisting xxx "$TMPDIR"
    
    # Check that the command succeeded
    [ "$status" -eq 0 ]
    
    # Check the log file contains "No files were modified"
    grep -q "No files were modified" $TMPDIR/test_output.log
}



##################
# OUTPUT TO STDOUT
##################

# Alternative tests that check stdout directly (if --log doesn't work as expected)
@test "replacer stdout shows 3 occurrences of 'lumin'" {
    run ./replacer.sh --dry-run lumin xxx "$TMPDIR"
    
    # Check that the command succeeded
    [ "$status" -eq 0 ]
    
    # Check the output contains "3 occurrence(s)"
    [[ "$output" =~ "3 occurrence(s)" ]]
}

@test "replacer stdout shows 4 occurrences of 'dolorem'" {
    run ./replacer.sh --dry-run dolorem xxx "$TMPDIR"
    
    # Check that the command succeeded
    [ "$status" -eq 0 ]
    
    # Check the output contains "4 occurrence(s)"
    [[ "$output" =~ "4 occurrence(s)" ]]
}

@test "replacer stdout shows 5 occurrences of 'dolorem' with ignore-case" {
    run ./replacer.sh --dry-run --ignore-case dolorem xxx test/fixtures/
    
    # Check that the command succeeded
    [ "$status" -eq 0 ]
    
    # Check the output contains "5 occurrence(s)"
    [[ "$output" =~ "5 occurrence(s)" ]]
}

@test "replacer stdout shows no files modified for nonexisting text" {
    run ./replacer.sh --dry-run nonexisting xxx "$TMPDIR"
    
    # Check that the command succeeded
    [ "$status" -eq 0 ]
    
    # Check the output contains "No files were modified"
    [[ "$output" =~ "No files were modified" ]]
}

@test "replacer stdout shows no files modified when depth is 1" {
    run ./replacer.sh --dry-run --depth=1 neon xxx "$TMPDIR"
    
    # Check that the command succeeded
    [ "$status" -eq 0 ]
    
    # Check the output contains "No files were modified"
    [[ "$output" =~ "No files were modified" ]]
}

@test "replacer stdout shows "3 occurence(s)" when depth is 2" {
    run ./replacer.sh --dry-run --depth=2 neon xxx "$TMPDIR"
    
    # Check that the command succeeded
    [ "$status" -eq 0 ]
    
    # Check the output contains "No files were modified"
    [[ "$output" =~ "3 occurrence(s)" ]]
}
