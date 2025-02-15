**Prelude** is a tool that helps you quickly generate context prompts for large-language models (LLMs). It’s especially handy when you want the LLM to analyze or improve code that spans multiple files and directories. Prelude is a single file shell script that works on macOS, Linux, and Windows (via WSL), and is well suited for use in CI/CD pipelines or environments where you cannot install additional software.

**Prelude** creates a prompt by:
1. Listing the file tree (including subdirectories, hidden files, and even binary files).
2. Concatenating the contents of **text** files (skipping binary files) into one consolidated text block.

By default, Prelude **copies** this final prompt to your clipboard. You can also **save** it to a file or choose to **display** it in your terminal.


### Usage

```sh
prelude [-P <relative_path>] [-F <output_filename>] [-M <match_pattern>] [-X <exclude_pattern>] [-g] [-c] [-d] [--help] [--manual]
```

**Options**:

- **`-P <relative_path>`**  
  Include files from a specific relative path (can be used multiple times). If omitted, Prelude uses the current directory.

- **`-F <output_filename>`**  
  Save the generated prompt to this file. If not specified, the prompt is only copied to the clipboard (and displayed in non-interactive modes).

- **`-M <match_pattern>`**  
  Only include files that match the given patterns. Use `|` to separate multiple patterns (e.g., `"*.txt|*.md"`). Matching is **case-insensitive** by default.

- **`-X <exclude_pattern>`**  
  Exclude files that match the given patterns. Use `|` to separate multiple patterns. Case-insensitive by default unless `-c` is used.

- **`-g`**  
  Only include files that are **git-tracked**. Untracked or ignored files are excluded. If there is no local `.git` directory, the script errors.

- **`-c`**  
  Make pattern matching **case-sensitive** for both `-M` and `-X`. By default, matching is case-insensitive.

- **`-d`**  
  Force **display** of the final prompt on **stdout**. If omitted, Prelude is “quiet” in an interactive shell (only copying the result to clipboard). When running under a non-interactive environment (like a CI/CD pipeline or a test harness), Prelude prints the prompt by default.

- **`--help`**  
  Show a brief usage message.

- **`--manual`**  
  Show the more detailed manual text.

---

### Examples

- **`prelude`**  
  Generate a prompt for **all files** in the current directory. Since you’re presumably interactive, it **copies** the prompt to your clipboard, but **does not** display it in your terminal unless you add `-d`.

- **`prelude -P src`**  
  Generate a prompt from the `src` subdirectory, copying to clipboard (quiet by default in an interactive shell).

- **`prelude -F prompt.txt`**  
  Generate a prompt for all files, save it to `prompt.txt`, and copy to clipboard (quiet by default).

- **`prelude -P src -F prompt.txt -d`**  
  Include only files below `src`, save the prompt to `prompt.txt`, **and** print the final prompt to stdout.

- **`prelude -M "*.txt|*.py"`**  
  Only include `.txt` and `.py` files. Copy to clipboard, no stdout if interactive.

- **`prelude -X "*.log|*.tmp"`**  
  Exclude any `.log` or `.tmp` files.

- **`prelude -g`**  
  Include only **git-tracked** files from the current directory.

- **`prelude -g -P src -M "*.js"`**  
  Include only git-tracked `.js` files below `src`.

- **`prelude -c -M "*CASE.txt"`**  
  Case-sensitive match for `*CASE.txt`. Would **not** match `uppercase.txt` if the pattern is `*CASE.txt`.

---

### How It Works

1. **File Tree + Contents**  
   Prelude uses `tree` to produce a file/directory listing. It then concatenates the contents of each text file (skipping binary files) into one big text block.

2. **Clipboard Copy**  
   If a clipboard tool (`pbcopy`, `xclip`, `xsel`, `clip`, or `wl-copy`) is found, Prelude places the entire prompt there.

3. **Quiet vs. Display**  
   - In an **interactive shell** (where stdout is a TTY), Prelude doesn’t print the final prompt unless `-d` is used.  
   - In a **non-interactive** environment (like when running under tests or piping to another command), it **automatically** prints everything to stdout.

4. **Git Integration** (`-g`)  
   - If you specify `-g`, only files tracked by Git appear in the listing. Untracked/ignored files are skipped.  
   - If no `.git` directory is present, the script exits with an error.

5. **Case-Insensitive Matching**  
   - By default, patterns for `-M` and `-X` ignore case. Use `-c` to enforce case sensitivity.

6. **.gitignore / .preludeignore**  
   By default, Prelude also excludes anything that matches patterns in `.gitignore` and `.preludeignore` (and you can add additional exclusions with `-X`).

---

### Installation

**Homebrew** users can install via:

```sh
brew tap aerugo/prelude
brew install prelude
```

Otherwise, install manually by placing the `prelude` script in your `$PATH` and ensuring it’s **executable**.

This script generates a prompt containing the file tree and concatenated file contents of a specified directory. The prompt can be copied to the clipboard and optionally saved to a file.


#### Options

- `-P <relative_path>`: Specify a relative path to include only files below that path. If not specified, the script will include all files in the current directory and its subdirectories.
- `-F <output_filename>`: Specify a filename to save the generated prompt. If not specified, the prompt will only be copied to the clipboard.
- `-M <match_pattern>`: Specify pattern(s) to match filenames and only include those files. Patterns are case-insensitive by default.  Valid wildcard operators are '*' (any zero or more characters), '?' (any single character), '[...]' (any single character listed between brackets (optional - (dash) for character range may be used: ex: [A-Z]), and '[^...]' (any single character not listed in brackets) and '|' separates alternate patterns.
- `-g`: Only include files tracked by git.
- `-c`: Respect case sensitivity in pattern matching. 
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

- The script checks for the presence of clipboard commands (pbcopy, xclip, xsel, clip, wl-copy) and uses the first one found to copy the prompt to the clipboard. If none are found and no output file is specified, the prompt is printed to stdout.
- The script reads `.gitignore` and `.preludeignore` files to exclude specified patterns from the file tree.

### Dependencies

- **`tree`**: Required for the directory listing.
- **`git`**: Required for `-g` (git-tracked) mode.
- **A clipboard tool** (optional): Prelude checks for `pbcopy`, `xclip`, `xsel`, `clip`, or `wl-copy` to copy the prompt. If none is found, no error is thrown (the script still runs), but no actual copying will occur.

### Error Handling

- If the specified path does not exist or is not a directory, an error message is displayed, and the script exits.
- If no clipboard command is found and no output file is specified, the prompt is printed to stdout.
- If no clipboard command is found and an output file is specified, the prompt is saved to the file without copying to the clipboard.

### Completion

- The script copies the generated prompt to the clipboard and optionally saves it to a specified file.
- A message is printed to indicate the completion, listing the files included in the prompt.

### Testing

Prelude includes a [BATS](https://github.com/bats-core/bats-core) test suite. Install BATS, then run:

```sh
bats test_prelude.bats
```

This covers different usage scenarios (paths, patterns, git-only mode, ignoring files, invalid flags, hidden files, etc.) to ensure Prelude’s reliability.
