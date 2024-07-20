#!/usr/bin/env bats

setup() {
    # Create a temporary directory for testing
    TEST_DIR=$(mktemp -d)

    # Copy the script to the test directory
    cp prelude "$TEST_DIR"
    cd "$TEST_DIR"
    chmod +x ./prelude

    # Create some test files and directories
    mkdir -p src/nested
    echo "Hello, world!" > src/test.txt
    echo "print('Hello')" > src/test.py
    echo "function test() {}" > src/nested/test.js
    echo ".DS_Store" > .gitignore
    echo "*.log" > .preludeignore
    echo "test.log" > src/test.log
    echo ".DS_Store" > src/.DS_Store
}

teardown() {
    # Clean up the temporary directory
    cd "$OLDPWD"
    rm -rf "$TEST_DIR"
}

@test "Script runs without arguments" {
    run ./prelude
    [ "$status" -eq 0 ]
    [[ "$output" == *"Got prompt with file tree and concatenated file contents."* ]]
    [[ "$output" == *"The prompt has been copied to the clipboard."* ]]
}

@test "Script shows help with --help flag" {
    run ./prelude --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]
    [[ "$output" == *"-P <relative_path>"* ]]
}

@test "Script shows manual with --manual flag" {
    run ./prelude --manual
    [ "$status" -eq 0 ]
    [[ "$output" == *"MANUAL"* ]]
    [[ "$output" == *"OPTIONS"* ]]
    [[ "$output" == *"EXAMPLES"* ]]
}

@test "Script works with -P flag" {
    run ./prelude -P src
    [ "$status" -eq 0 ]
    [[ "$output" == *"src/test.txt"* ]]
    [[ "$output" == *"src/test.py"* ]]
    [[ "$output" != *".gitignore"* ]]
}

@test "Script works with -F flag" {
    run ./prelude -F output.txt
    [ "$status" -eq 0 ]
    [[ "$output" == *"The prompt has been saved to output.txt."* ]]
    [ -f output.txt ]
}

@test "Script works with -M flag for single pattern" {
    run ./prelude -M "*.txt"
    [ "$status" -eq 0 ]
    [[ "$output" == *"src/test.txt"* ]]
    [[ "$output" != *"src/test.py"* ]]
}

@test "Script works with -M flag for multiple patterns" {
    run ./prelude -M "*.txt|*.py"
    [ "$status" -eq 0 ]
    [[ "$output" == *"src/test.txt"* ]]
    [[ "$output" == *"src/test.py"* ]]
    [[ "$output" != *"src/nested/test.js"* ]]
}

@test "Script respects .gitignore" {
    echo ".DS_Store" > src/.DS_Store
    run ./prelude
    [ "$status" -eq 0 ]
    [[ "$output" != *"src/.DS_Store"* ]]
}

@test "Script respects .preludeignore" {
    echo "test.log" > src/test.log
    run ./prelude
    [ "$status" -eq 0 ]
    [[ "$output" != *"src/test.log"* ]]
}

@test "Script handles non-existent path" {
    run ./prelude -P non_existent_path
    [ "$status" -eq 1 ]
    [[ "$output" == *"Error: The specified path 'non_existent_path' does not exist or is not a directory."* ]]
}

@test "Script handles invalid option" {
    run ./prelude -Z
    [ "$status" -eq 1 ]
    [[ "$output" == *"Invalid option: Z"* ]]
}