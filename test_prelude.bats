#!/usr/bin/env bats

setup() {
    # Create a temporary directory for testing
    TEST_DIR=$(mktemp -d)

    # Copy the script to the test directory
    cp prelude "$TEST_DIR"
    cd "$TEST_DIR"
    chmod +x ./prelude

    # Initialize git repository
    git init
    git config user.email "test@example.com"
    git config user.name "Test User"

    # Create some test files and directories
    mkdir -p src/nested
    echo "Hello, world!" > src/test.txt
    echo "print('Hello')" > src/test.py
    echo "function test() {}" > src/nested/test.js
    echo ".DS_Store" > .gitignore
    echo "*.log" > .preludeignore
    echo "test.log" > src/test.log
    echo ".DS_Store" > src/.DS_Store
    echo "This file is not tracked" > src/untracked.txt

    # Add and commit files
    git add src/test.txt src/test.py src/nested/test.js .gitignore .preludeignore
    git commit -m "Initial commit"
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
    run ./prelude -P src -F output.txt
    [ "$status" -eq 0 ]
    [[ "$output" == *"The prompt has been saved to output.txt."* ]]
    [ -f output.txt ]
    cat output.txt
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

@test "Script concatenates files" {
    run ./prelude -P src -F output.txt
    [ "$status" -eq 0 ]
    [ -f output.txt ]
    grep -q "Hello, world!" output.txt
    grep -q "print('Hello')" output.txt
    grep -q "function test() {}" output.txt
}

@test "Script concatenates files with -M flag" {
    run ./prelude -P src -M "*.txt|*.py" -F output.txt
    [ "$status" -eq 0 ]
    [ -f output.txt ]
    grep -q "Hello, world!" output.txt
    grep -q "print('Hello')" output.txt
    ! grep -q "function test() {}" output.txt
}

@test "Script works with -g flag" {
    run git status
    echo "Git status: $output"
    run ./prelude -g
    [ "$status" -eq 0 ]
    [[ "$output" == *"src/test.txt"* ]]
    [[ "$output" == *"src/test.py"* ]]
    [[ "$output" == *"src/nested/test.js"* ]]
    [[ "$output" != *"src/untracked.txt"* ]]
    [[ "$output" != *"src/test.log"* ]]
}

@test "Script works with -g and -P flags" {
    run git status
    echo "Git status: $output"
    run ./prelude -g -P src
    [ "$status" -eq 0 ]
    [[ "$output" == *"src/test.txt"* ]]
    [[ "$output" == *"src/test.py"* ]]
    [[ "$output" == *"src/nested/test.js"* ]]
    [[ "$output" != *"src/untracked.txt"* ]]
}

@test "Script works with -g and -M flags" {
    run git status
    echo "Git status: $output"
    run ./prelude -g -M "*.txt|*.py"
    [ "$status" -eq 0 ]
    [[ "$output" == *"src/test.txt"* ]]
    [[ "$output" == *"src/test.py"* ]]
    [[ "$output" != *"src/nested/test.js"* ]]
}

@test "Script works with -g, -P, and -M flags" {
    run git status
    echo "Git status: $output"
    run ./prelude -g -P src -M "*.txt"
    [ "$status" -eq 0 ]
    [[ "$output" == *"src/test.txt"* ]]
    [[ "$output" != *"src/test.py"* ]]
    [[ "$output" != *"src/nested/test.js"* ]]
}

@test "Script concatenates only git-tracked files with -g flag" {
    run git status
    echo "Git status: $output"
    run ./prelude -g -F output.txt
    [ "$status" -eq 0 ]
    [ -f output.txt ]
    cat output.txt
    grep -q "Hello, world!" output.txt
    #grep -q "print('Hello')" output.txt
    #grep -q "function test() {}" output.txt
    #! grep -q "This file is not tracked" output.txt
}
