
# Pre-commit Hook Documentation

This pre-commit hook ensures all staged Dart files are properly formatted and analyzed before committing.

## Installation

1. Make sure both Dart and Flutter are installed and added to your PATH.
2. Ensure that the hook is executable:

   ```bash
   chmod +x .githooks/pre-commit
   ```

3. Configure Git to use this local hook folder:

   ```bash
   git config core.hooksPath .githooks
   ```

4. (Optional but recommended) Install `jq` for better report parsing:

    ```bash
    brew install jq
   ```

5. (If you using pana) Add pana reports directory to `.gitignore`:

    ```bash
    echo -e "\n# Pana reports\n.pana_reports/" >> .gitignore
    ```

## Usage

1. Stage your changes as usual with `git add`.
2. When running `git commit`, the hook checks for:
   - Staged Dart files and formats them via `dart format`.
   - Potential issues reported by `flutter analyze`.
3. If any issues are found, the hook will reject the commit until they are resolved.

## Troubleshooting

- If you see “Dart command not found” or “Flutter command not found,” ensure those are installed and accessible in your PATH.
- If formatting fails, fix or remove the problematic files from the staging area.
- Use `git commit --no-verify` to bypass the hook in emergencies, though this is not recommended.
