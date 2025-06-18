
Utility scripts to help prepare data for [Elm](https://uit.stanford.edu/service/elm-storage) upload and extract data retrieved from Elm.

### Intended sequence of usage
1. **dwalk_oak_user.sbatch**: To find and log special files that are unsupported by `tar` and `dtar`, and paths that lack read permissions by the user performing archival (helpful for group admins).
2. **parse_errors.sh**: Can be used to parse errors and extract paths from `dwalk_oak_user.sbatch` or the `elm_archive` tool.
3. **delete_files.sh**: Review paths identified by `parse_errors.sh` and pass to this script to delete the unsupported files.
4. **submit_extract.sh**: To extract files downloaded from Elm using `tar` or `dtar`. This is a helper script to run `extract_tar.sbatch`.

Please execute any script to learn about usage information and expected arguments.   
    
Elm documentation: https://docs.elm.stanford.edu/    
Thanks to the amazing team at Stanford Research Computing for developing Elm!
