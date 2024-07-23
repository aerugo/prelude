## Prelude

Prelude is an extremely simple tool to help you make context prompts for LLMs with long context windows. It is useful when using LLMs to improve code that is distributed over multiple files and directories. Prelude generates a prompt containing the file tree and concatenated file contents of a specified directory. The prompt is automatically copied to the clipboard and optionally saved to a file.

### Usage

```sh
prelude [-P <relative_path>] [-F <output_filename>] [-M <match_pattern>] [-g] [--help] [--manual]
```

Files and directories that are to be excluded can be listed in a `.preludeignore` file in the directory where you run prelude. Prelude will also ignore anything in the `.gitignore`.

### Example

```sh
$ prelude -M "*.md|*test*" -F prompt.txt
Got prompt with file tree and concatenated file contents.
Files included in the prompt are:
/Users/hugi/GitRepos/prelude
/Users/hugi/GitRepos/prelude/README.md
/Users/hugi/GitRepos/prelude/test_prelude.bats

1 directory, 2 files
The prompt has been copied to the clipboard.
The prompt has been saved to prompt.txt.
```

#### prompt.txt

```plaintext
I want you to help me fix some issues with my code. I have attached the code and file structure.

File Tree:
~/prelude
~/README.md
~/test_prelude.bats

1 directory, 2 files

Concatenated Files:

--- File: /Users/hugi/GitRepos/prelude/README.md ---

... <content of README.md> ...

--- File: /Users/hugi/GitRepos/prelude/test_prelude.bats ---

... <content of test_prelude.bats> ...
```

### Install with Homebrew

```sh
brew tap aerugo/prelude
brew install prelude
```

### Manual

This script generates a prompt containing the file tree and concatenated file contents of a specified directory. The prompt can be copied to the clipboard and optionally saved to a file.


#### Options

- `-P <relative_path>`: Specify a relative path to include only files below that path. If not specified, the script will include all files in the current directory and its subdirectories.
- `-F <output_filename>`: Specify a filename to save the generated prompt. If not specified, the prompt will only be copied to the clipboard.
- `-M <match_pattern>`: Specify pattern(s) to match filenames and only include those files.  Valid wildcard operators are '*' (any zero or more characters), '?' (any single character), '[...]' (any single character listed between brackets (optional - (dash) for character range may be used: ex: [A-Z]), and '[^...]' (any single character not listed in brackets) and '|' separates alternate patterns.
- `-g`: Only include files tracked by git.
- `--help`: Display help information.
- `--manual`: Display the manual.


#### Examples

- `./prelude`: Generate a prompt for all files in the current directory and copy it to the clipboard.
- `./prelude -P src`: Generate a prompt for all files below the specified path and copy it to the clipboard.
- `./prelude -F prompt.txt`: Generate a prompt for all files in the current directory and save it to a file.
- `./prelude -P src -F prompt.txt`: Generate a prompt for all files below the specified path and save it to a file.
- `./prelude -M "*.txt|*.py"`: Generate a prompt for all .txt and .py files.
- `./prelude -M "test*"`: Generate a prompt for all files starting with 'test'.
- `./prelude -g`: Generate a prompt for all git-tracked files in the current directory.
- `./prelude -g -P src`: Generate a prompt for all git-tracked files below the specified path.
- `./prelude -g -M "*.js"`: Generate a prompt for all git-tracked .js files.

### Notes

- The script checks for the presence of clipboard commands (`pbcopy`, `xclip`, `xsel`, `clip`) and uses the first one found to copy the prompt to the clipboard. If none are found, an error is displayed.
- The script reads `.gitignore` and `.preludeignore` files to exclude specified patterns from the file tree.

### Dependencies

- `tree`: Ensure that the `tree` command is installed and available in the system.
- `git`: Required when using the `-g` option to include only git-tracked files.

### Error Handling

- If the specified path does not exist or is not a directory, an error message is displayed, and the script exits.
- If no clipboard command is found, an error message is displayed, and the script exits.

### Completion

- The script copies the generated prompt to the clipboard and optionally saves it to a specified file.
- A message is printed to indicate the completion, listing the files included in the prompt.

### Testing

Prelude comes with a comprehensive test suite using the Bats (Bash Automated Testing System) framework. The tests cover various scenarios including:

- Running the script without arguments
- Using different flags (-P, -F, -M, -g)
- Respecting `.gitignore` and `.preludeignore` files
- Handling invalid inputs and edge cases

To run the tests, make sure you have Bats installed and then run:

```sh
bats test_prelude.bats
```

This will execute all the tests and provide a summary of the results, ensuring the reliability and correctness of the Prelude tool.