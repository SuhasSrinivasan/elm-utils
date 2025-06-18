# elm-utils

Utility scripts to help prepare data for Elm upload and extract data retrieved from Elm.

## Sequence of scripts
1. dwalk_oak_user.sbatch: To find and log special files that are unsupported by tar.
2. parse_errors.sh: Can be used to parse errors and extract paths from `dwalk_oak_user.sbatch` or the `elm_archive` tool.
