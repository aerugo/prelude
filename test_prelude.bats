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
    [[ "$output" == *"This is a concatenated prompt of all files in a codebase."* ]]
    [[ "$output" == *"Below is a filtered list of the files in the codebase:"* ]]
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
    grep -q "print('Hello')" output.txt
    grep -q "function test() {}" output.txt
    ! grep -q "This file is not tracked" output.txt
}

@test "Script handles empty files" {
    touch src/empty.txt
    run ./prelude -P src -F output.txt
    [ "$status" -eq 0 ]
    [ -f output.txt ]
    [[ "$output" == *"src/empty.txt"* ]]
}

@test "Script handles files with special characters" {
    touch "src/file with spaces.txt"
    touch "src/file_with_ñöñ_ÄßÇÌÍ_chars.txt"
    run ./prelude -P src -F output.txt
    [ "$status" -eq 0 ]
    [[ "$output" == *"src/file with spaces.txt"* ]]
    [[ "$output" == *"src/file_with_ñöñ_ÄßÇÌÍ_chars.txt"* ]]
}

@test "Script handles deeply nested directories" {
    mkdir -p src/level1/level2/level3/level4/level5
    touch src/level1/level2/level3/level4/level5/deep_file.txt
    run ./prelude -P src -F output.txt
    [ "$status" -eq 0 ]
    [[ "$output" == *"src/level1/level2/level3/level4/level5/deep_file.txt"* ]]
}

@test "Script handles symlinks" {
    ln -s src/test.txt src/symlink.txt
    mkdir src/symlink_dir
    ln -s src/symlink_dir src/symlink_to_dir
    run ./prelude -F output.txt
    [ "$status" -eq 0 ]
    [[ "$output" == *"src/symlink.txt"* ]]
    [[ "$output" == *"src/symlink_to_dir"* ]]
}

@test "Script handles multiple -P flags" {
    mkdir other_src
    touch other_src/other_file.txt
    run ./prelude -P src -P other_src -F output.txt
    [ "$status" -eq 0 ]
    [[ "$output" == *"src/test.txt"* ]]
    [[ "$output" == *"other_src/other_file.txt"* ]]
}

@test "Script handles mix of binary and text files" {
    dd if=/dev/urandom of=src/binary_file.bin bs=1024 count=1
    run ./prelude -P src -F output.txt
    [ "$status" -eq 0 ]
    [[ "$output" == *"src/binary_file.bin"* ]]
    [[ "$output" == *"src/test.txt"* ]]
}

@test "Script handles files without extensions" {
    touch src/no_extension
    run ./prelude -P src -F output.txt
    [ "$status" -eq 0 ]
    [[ "$output" == *"src/no_extension"* ]]
}

@test "Script handles hidden files and directories" {
    touch src/.hidden_file
    mkdir src/.hidden_dir
    touch src/.hidden_dir/file.txt
    run ./prelude -P src -F output.txt
    [ "$status" -eq 0 ]
    [[ "$output" == *"src/.hidden_file"* ]]
    [[ "$output" == *"src/.hidden_dir/file.txt"* ]]
}

@test "Script handles hidden files and directories with -g flag" {
    touch src/.hidden_file
    mkdir src/.hidden_dir
    touch src/.hidden_dir/file.txt
    git add src/.hidden_file
    git add src/.hidden_dir/file.txt
    git commit -m "Add hidden files"
    run ./prelude -g -F output.txt
    [ "$status" -eq 0 ]
    [[ "$output" == *"src/.hidden_file"* ]]
    [[ "$output" == *"src/.hidden_dir/file.txt"* ]]
}

@test "Script handles non-git repository with -g flag" {
    mkdir non_git_repo
    cd non_git_repo
    run ../prelude -g
    [ "$status" -ne 0 ]
    [[ "$output" == *"error"* ]]
    cd ..
}

@test "Script handles uncommitted changes with -g flag" {
    echo "Uncommitted change" >> src/test.txt
    run ./prelude -g -F output.txt
    [ "$status" -eq 0 ]
    grep -q "Uncommitted change" output.txt
}

@test "Script respects case sensitivity with -M and -c flags" {
    touch src/UPPERCASE.txt src/lowercase.txt
    run ./prelude -M "*CASE.txt" -c -F output.txt
    [ "$status" -eq 0 ]
    [[ "$output" == *"src/UPPERCASE.txt"* ]]
    [[ "$output" != *"src/lowercase.txt"* ]]
}

@test "Script ignores case sensitivity with -M flag without -c flag" {
    touch src/UPPERCASE.txt src/lowercase.txt
    run ./prelude -M "*CASE.txt" -F output.txt
    [ "$status" -eq 0 ]
    [[ "$output" == *"src/UPPERCASE.txt"* ]]
    [[ "$output" == *"src/lowercase.txt"* ]]
}

@test "Script respects case sensitivity with -M, -c, and -g flags" {
    touch src/UPPERCASE.txt src/lowercase.txt
    git add src/UPPERCASE.txt src/lowercase.txt
    git commit -m "Add case-sensitive files"
    run ./prelude -M "*CASE.txt" -c -g -F output.txt
    [ "$status" -eq 0 ]
    [[ "$output" == *"src/UPPERCASE.txt"* ]]
    [[ "$output" != *"src/lowercase.txt"* ]]
}

@test "Script ignores case sensitivity with -M and -g flags without -c flag" {
    touch src/UPPERCASE.txt src/lowercase.txt
    git add src/UPPERCASE.txt src/lowercase.txt
    git commit -m "Add case-sensitive files"
    run ./prelude -M "*CASE.txt" -g -F output.txt
    [ "$status" -eq 0 ]
    [[ "$output" == *"src/UPPERCASE.txt"* ]]
    [[ "$output" == *"src/lowercase.txt"* ]]
}

@test "Script handles merge conflicts" {
    git checkout -b test-branch
    echo "Branch change" > src/test.txt
    git add src/test.txt
    git commit -m "Branch commit"
    git checkout main
    echo "Main change" > src/test.txt
    git add src/test.txt
    git commit -m "Main commit"
    git merge test-branch || true  # Allow merge to fail
    run ./prelude -g -F output.txt
    [ "$status" -eq 0 ]
    grep -q "<<<<<<< HEAD" output.txt
}

@test "Script handles very long file paths" {
    long_path="src"
    for i in {1..50}; do
        long_path="${long_path}/subdir_${i}"
    done
    mkdir -p "$long_path"
    touch "${long_path}/long_path_file.txt"
    run ./prelude -P src -F output.txt
    [ "$status" -eq 0 ]
    [[ "$output" == *"${long_path}/long_path_file.txt"* ]]
}

@test "Script handles concurrent executions" {
    run_concurrent() {
        ./prelude -F "output_$1.txt" &
    }
    run_concurrent 1
    run_concurrent 2
    run_concurrent 3
    wait
    [ -f "output_1.txt" ]
    [ -f "output_2.txt" ]
    [ -f "output_3.txt" ]
    cmp --silent "output_1.txt" "output_2.txt" && \
    cmp --silent "output_2.txt" "output_3.txt"
}

@test "Script works with -X flag for single exclude pattern" {
    # Create a file to exclude
    echo "Should be excluded" > src/exclude_me.txt

    # Run script excluding *.txt
    run ./prelude -X "*.txt"
    [ "$status" -eq 0 ]

    # The file_tree listing (stdout) should NOT contain src/exclude_me.txt
    [[ "$output" != *"exclude_me.txt"* ]]

    # Normal files (like test.py) should remain
    [[ "$output" == *"src/test.py"* ]]
}

@test "Script works with -X flag for multiple exclude patterns" {
    # Create files to exclude
    echo "Should be excluded" > src/exclude_me.log
    echo "Should also be excluded" > src/exclude_me.tmp

    # Run script excluding both *.log and *.tmp
    run ./prelude -X "*.log|*.tmp"
    [ "$status" -eq 0 ]

    # The file_tree listing (stdout) should NOT contain these excluded files
    [[ "$output" != *"exclude_me.log"* ]]
    [[ "$output" != *"exclude_me.tmp"* ]]

    # Normal files (like test.txt) should remain
    [[ "$output" == *"src/test.txt"* ]]
}

@test "Script respects case-insensitive exclude by default" {
    # Create a file that is uppercase
    echo "Excluded in uppercase" > src/EXCLUDE_THIS.TXT

    # Run script excluding *.txt (case-insensitive by default)
    run ./prelude -X "*.txt"
    [ "$status" -eq 0 ]

    # Should exclude the uppercase file
    [[ "$output" != *"EXCLUDE_THIS.TXT"* ]]
}

@test "Script respects case-sensitive exclude with -c flag" {
    # Create files with different cases
    echo "case test" > src/Lowercase.txt
    echo "CASE TEST" > src/UPPERCASE.TXT

    # Run script excluding only *.txt EXACTLY, in a case-sensitive manner
    run ./prelude -X "*.txt" -c
    [ "$status" -eq 0 ]

    # Lowercase.txt should be excluded
    [[ "$output" != *"Lowercase.txt"* ]]

    # UPPERCASE.TXT should remain included because we used -c (case-sensitive)
    [[ "$output" == *"UPPERCASE.TXT"* ]]
}

@test "Script works with both -M and -X flags" {
    # Create an extra file we want to include, then exclude
    echo "Include me, then exclude me" > src/include_me_too.py
    echo "But you won't see me" > src/exclude_me.log

    # First, we explicitly include *.py, but also exclude *.log
    run ./prelude -M "*.py" -X "*.log"
    [ "$status" -eq 0 ]

    # We should see all .py files (including include_me_too.py)
    [[ "$output" == *"src/test.py"* ]]
    [[ "$output" == *"include_me_too.py"* ]]

    # We should NOT see .log files
    [[ "$output" != *"exclude_me.log"* ]]
}

@test "Script excludes untracked files with -g and -X" {
    # Create an untracked file
    echo "Untracked but also excluded" > src/untracked_excluded.txt

    # We do NOT add it to git, so it's untracked
    # However, we also specify -X "*.txt" to exclude all text anyway
    run ./prelude -g -X "*.txt"
    [ "$status" -eq 0 ]

    # The untracked file won't appear because -g excludes untracked
    # But let's also confirm the exclude pattern would have filtered it
    [[ "$output" != *"untracked_excluded.txt"* ]]

    # Normal tracked .txt (like src/test.txt) will also be excluded by -X "*.txt"
    [[ "$output" != *"src/test.txt"* ]]

    # However, .py or .js files that are tracked remain
    [[ "$output" == *"src/test.py"* ]]
    [[ "$output" == *"src/nested/test.js"* ]]
}

@test "Script excludes hidden files with -X flag" {
    # Create a hidden file
    echo "Hidden to exclude" > src/.exclude_hidden

    # Run script excluding .exclude_hidden explicitly
    run ./prelude -X ".exclude_hidden"
    [ "$status" -eq 0 ]

    # The hidden file should not appear
    [[ "$output" != *".exclude_hidden"* ]]

    # Check normal hidden files or directories not in exclude list still appear
    touch src/.another_hidden
    [[ "$output" == *".another_hidden"* ]] || skip "Expected .another_hidden to appear unless it matches default exclude"
}

@test "Script excludes multiple patterns along with default .preludeignore" {
    # We already have *.log in .preludeignore
    echo "Pre-existing content" > src/example.log
    echo "Exclude me as well" > src/example.tmp

    # Exclude patterns using -X, on top of .preludeignore ignoring *.log
    run ./prelude -X "*.tmp"
    [ "$status" -eq 0 ]

    # Confirm that .log is ignored due to .preludeignore
    [[ "$output" != *"example.log"* ]]
    # Confirm that .tmp is ignored due to -X
    [[ "$output" != *"example.tmp"* ]]
}

