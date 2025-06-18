
Utility scripts to help prepare data for Elm upload and extract data retrieved from Elm.

### Intended sequence of script usage
1. **dwalk_oak_user.sbatch**: To find and log special files that are unsupported by tar and paths that lack read permissions by user performing archival (helpful for group admins).
2. **parse_errors.sh**: Can be used to parse errors and extract paths from `dwalk_oak_user.sbatch` or the `elm_archive` tool.
3. **delete_files.sh**: Review paths identified by `parse_errors.sh` and pass to this script to delete the unsupported files.
4. **submit_extract.sh**: To extract files downloaded from Elm using `tar` or `dtar`. This is a helper script to run `extract_tar.sbatch`.
