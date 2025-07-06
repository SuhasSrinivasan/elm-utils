
Utility scripts to assist with the following operations related to [Elm](https://uit.stanford.edu/service/elm-storage) archival:
1. Check if files and permissions are supported for upload and handle issues
2. Extract data retrieved from Elm
3. Delete archived data from Oak

### Intended sequence of usage
1. **dwalk_oak_user.sbatch**: To find and log special files that are unsupported by `tar` and `dtar`, and paths that lack read permissions by the user performing archival (helpful for group admins).
2. **parse_errors.sh**: Can be used to parse errors and extract paths from `dwalk_oak_user.sbatch` or the `elm_archive` tool.
3. **delete_files.sh**: Review paths identified by `parse_errors.sh` and pass to this script to delete the unsupported files.
4. **submit_extract.sh**: To extract files downloaded from Elm using `tar` or `dtar`. This is a helper script to run `extract_tar.sbatch`.
5. **clear_directories.sh**: After archival is completed and verified, use this script _**with caution**_ to delete Oak user directories. The Oak user directories are listed in the accompanying file `clear_directories_list.txt`.  

Please execute any script to learn about usage information and expected arguments.   
    
Elm documentation: https://docs.elm.stanford.edu/    
Thanks to the amazing team at Stanford Research Computing for developing Elm!
