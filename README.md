Prelude is an extremely simple tool to help you make context prompts for LLMs with long context windows. It is useful when using LLMs to improve code that is distributed over multiple files and directories. Prelude generates a prompt containing the file tree and concatenated file contents of a specified directory. The prompt is automatically copied to the clipboard and optionally saved to a file.

## Usage

```
prelude [-P <relative_path>] [-F <output_filename>] [-M <match_pattern>] [--help] [--manual]
```

Files and directories that are to be excluded can be listed in a .preludeignore file in the directory where you run prelude. Prelude will also ignore anything in the .gitignore.

## Install with Homebrew

```
brew tap aerugo/prelude
brew install prelude
```

### Options

- `-P <relative_path>`: Specify a relative path to include only files below that path. If not specified, the script will include all files in the current directory and its subdirectories.
- `-F <output_filename>`: Specify a filename to save the generated prompt. If not specified, the prompt will only be copied to the clipboard.
- `-M <match_pattern>`: Specify pattern(s) to match filenames and only include those files. Use '|' as a delimiter for multiple patterns.
- `--help`: Display help information.
- `--manual`: Display the manual.

## Manual

This script generates a prompt containing the file tree and concatenated file contents of a specified directory. The prompt can be copied to the clipboard and optionally saved to a file.

### Options

- `-P <relative_path>`: Specify a relative path to include only files below that path. If not specified, the script will include all files in the current directory and its subdirectories.
- `-F <output_filename>`: Specify a filename to save the generated prompt. If not specified, the prompt will only be copied to the clipboard.
- `-M <match_pattern>`: Specify pattern(s) to match filenames. Uses tree's pattern matching syntax. For multiple patterns, separate them with '|'. Use '*' for wildcards. The matching is case-insensitive by default.
- `--help`: Display help information.
- `--manual`: Display the manual.

### Examples

- `./prelude`: Generate a prompt for all files in the current directory and copy it to the clipboard.
- `./prelude -P src`: Generate a prompt for all files below the specified path and copy it to the clipboard.
- `./prelude -F prompt.txt`: Generate a prompt for all files in the current directory and save it to a file.
- `./prelude -P src -F prompt.txt`: Generate a prompt for all files below the specified path and save it to a file.
- `./prelude -M "*.txt|*.py"`: Generate a prompt for all .txt and .py files.
- `./prelude -M "test*"`: Generate a prompt for all files starting with 'test'.

## Notes

- The script checks for the presence of clipboard commands (`pbcopy`, `xclip`, `xsel`, `clip`, `wl-copy`) and uses the first one found to copy the prompt to the clipboard. If none are found, an error is displayed.
- The script reads `.gitignore` and `.preludeignore` files to exclude specified patterns from the file tree.

## Dependencies

- `tree`: Ensure that the `tree` command is installed and available in the system.

## Error Handling

- If the specified path does not exist or is not a directory, an error message is displayed, and the script exits.
- If no clipboard command is found, an error message is displayed, and the script exits.

## Completion

- The script copies the generated prompt to the clipboard and optionally saves it to a specified file.
- A message is printed to indicate the completion, listing the files included in the prompt.

## Testing

Prelude comes with a comprehensive test suite using the Bats (Bash Automated Testing System) framework. The tests cover various scenarios including:

- Running the script without arguments
- Using different flags (-P, -F, -M)
- Respecting .gitignore and .preludeignore files
- Handling invalid inputs and edge cases

To run the tests, make sure you have Bats installed and then run:

```
bats test_prelude.bats
```

This will execute all the tests and provide a summary of the results, ensuring the reliability and correctness of the Prelude tool.