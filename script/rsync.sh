#!/usr/bin/env bash

# Helper script for syncing files and directories programatically.

# Set Strict Mode
set -eou pipefail

readonly DOCKERIZEDIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

# Load libs
cd "$DOCKERIZEDIR"

# Load up the realpath lib
# shellcheck disable=SC1091
source ./lib/realpath

# Docker variables that we use globally
DOCKER_HOST=${DOCKER_MACHINE_NAME:-dev}
DOCKER_HOST_USER="$(docker-machine inspect --format "{{ .Driver.SSHUser }}" "$DOCKER_HOST")"
DOCKER_HOST_SSH_KEY="$(docker-machine inspect --format "{{ .Driver.SSHKeyPath }}" "$DOCKER_HOST")"
DOCKER_HOST_SSH_URL="$DOCKER_HOST_USER@$(docker-machine inspect --format "{{ .Driver.IPAddress }}" "$DOCKER_HOST")"

# Global paths that we will be sync'ing (provided on the command line)
PATHS_TO_SYNC=""
# Default set of things to not sync
EXCLUDES=".git/ *.log node_modules/ *.pyc public/build client/bower_components main/data *.egg-info .eslintrc.js nginx/www"
# Default set of things to include (empty)
INCLUDES=""
# Flags used for Rsync when sync'ing files
RSYNC_FLAGS="--archive --log-format 'Syncing %n: %i' --delete --omit-dir-times --inplace --whole-file -l"


#
# Usage: join SEPARATOR ARRAY
#
# Joins the values of ARRAY using SEPARATOR
#
join() {
  local separator="$1"
  shift
  local values=("$@")

  printf "%s$separator" "${values[@]}" | sed "s/$separator$//"
}


#
# Usage: flags FLAG OPTIONS
#
# Turns OPTIONS array into a series of flags with FLAG, wrapping each in quotes
#
# Examples:
#
# flags --exclude /foo /bar
#   Result: --exclude="/foo" --exclude="/bar"
#
flags() {
	local flag=${1:-}
	shift
    local opts=()
    opts=($@)

    if [[ "${#opts}" = 0 ]]; then
        echo ""
        return
    fi

	opt_flags=()
	for opt in "${opts[@]}"; do
		opt_flags+=("$flag=\"$opt\"")
	done

	echo "${opt_flags[@]}"
}

#
# Usage: find_path_to_sync_parent PATH
#
# Finds the parent folder of PATH from the PATHS_TO_SYNC global variable. When
# using rsync, we want to sync the exact folders the user specified when
# running the docker-osx-dev script. However, when we we use fswatch, it gives
# us the path of files that changed, which may be deeply nested inside one of
# the folders we're supposed to keep in sync. Therefore, this function lets us
# transform one of these nested paths back to one of the top level rsync paths.
#
find_path_to_sync_parent() {
  local path
  local normalized_path
  local paths_to_sync
  path="$1"
  normalized_path=$(realpath "$(eval echo "$path")")
  paths_to_sync=(${PATHS_TO_SYNC[@]})

  local path_to_sync=""
  for path_to_sync in "${paths_to_sync[@]}"; do
    if [[ "$normalized_path" == "$path_to_sync" || "$normalized_path" == $path_to_sync/* ]]; then
      echo "$path_to_sync"
      return
    fi
  done
}


#
# Usage: do_rsync PATH
#
# Uses rsync to sync PATH to the same PATH on the Docker Machine VM.
#
# Examples:
#
# do_rsync /foo
#   Result: the contents of /foo are rsync'ed to /foo on the Docker Machine VM
#
do_rsync() {
	local path
	local path_to_sync
    path="$1"
    path_to_sync=$(find_path_to_sync_parent "$path")

	if [[ -z "$path_to_sync" ]]; then
		echo "Internal error: can\'t sync '$path' because it doesn\'t seem to be part of any paths configured for syncing: ${PATHS_TO_SYNC[*]}"
	else
		local parent_folder
        parent_folder=$(dirname "$path_to_sync")

        local exclude_flags
        exclude_flags=$(flags --exclude "$EXCLUDES")
		local include_flags
        include_flags=$(flags --include "$INCLUDES")

		local rsh_flag="--rsh=\"ssh -i $DOCKER_HOST_SSH_KEY -o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null\""

		local rsync_cmd="rsync $RSYNC_FLAGS $include_flags $exclude_flags $rsh_flag $path_to_sync $DOCKER_HOST_SSH_URL:$parent_folder 2>&1 | grep -v \"^Warning: Permanently added\""

		eval "$rsync_cmd" 2>&1 || true
	fi
}


#
# Usage: do_sync [PATHS ...]
#
# Uses rsync to sync PATHS to the Docker Machine VM. If one of the values in
# PATHS is not valid (e.g. doesn't exist), it will be ignored.
#
# Examples:
#
# rsync /foo /bar
#   Result: /foo and /bar are rsync'ed to the Docker Machine
#
do_sync() {
  local paths_to_sync=("$@")
  local path=""

  for path in "${paths_to_sync[@]}"; do
    do_rsync "$path"
  done
}


#
# Usage: create_sync_directories [PATHS ...]
#
# Sets up all necessary parent directories and permissions for PATHS in the
# Docker Machine VM.
#
create_sync_directories() {
  local paths_to_sync=("$@")
  local dirs_to_create=()
  local path=""

  for path in "${paths_to_sync[@]}"; do
    local parent_dir
    parent_dir=$(dirname "$path")
    if [[ "$parent_dir" != "/" ]]; then
      dirs_to_create+=("$parent_dir")
    fi
  done

  local dir_string
  # TODO Find an alternative to the custom join function
  dir_string=$(join " " "${dirs_to_create[@]}")
  local mkdir_string="sudo mkdir -p $dir_string"
  local chown_string="sudo chown -R $DOCKER_HOST_USER $dir_string"
  local ssh_cmd="$mkdir_string && $chown_string"

  # echo "Creating parent directories in Docker VM: $ssh_cmd"
  docker-machine ssh "$DOCKER_HOST" "$ssh_cmd"
}


#
# Usage: tar_sync [PATHS ...]
#
# Use tar to set up the initial sync of PATHS in the Docker Machine VM, which
# is faster than letting rsync do it.
#
tar_sync() {
  local paths_to_sync=("$@")
  local path=""
  local parent_dir=""
  local base_name=""
  local excludes=(${EXCLUDES[@]})
  local exclude_flags=${excludes[*]/#/--exclude=}
  local includes=($INCLUDES)
  local include_flags=${includes[*]/#/--include=}

  for path in "${paths_to_sync[@]}"; do
    parent_dir=$(dirname "$path")
    base_name=$(basename "$path")
    if docker-machine ssh "$DOCKER_HOST" "test -e '$parent_dir/$base_name'" > /dev/null 2>&1; then
      echo "Skipped initial tar for $parent_dir/$base_name"
    else
      echo "Initial sync using tar for $parent_dir/$base_name"
      # shellcheck disable=SC2086
      tar -cC "$parent_dir" $exclude_flags "$base_name" | docker-machine ssh "$DOCKER_HOST" "tar -xC '$parent_dir'"
    fi
  done
}


#
# Usage: initial_sync
#
# Perform the initial sync of PATHS_TO_SYNC to the Docker Machine VM, including
# setting up all necessary parent directories and permissions.
#
initial_sync() {
    local paths_to_sync=(${PATHS_TO_SYNC[*]})
    echo "Performing initial sync of paths: ${paths_to_sync[*]}"

    create_sync_directories "${paths_to_sync[@]}"

    tar_sync "${paths_to_sync[@]}"

    echo "Starting sync paths: ${paths_to_sync[*]}"
    do_sync "${paths_to_sync[@]}"
    echo "Initial sync done"
}


#
# Usage: watch
#
# Watches the paths in the global variable PATHS_TO_SYNC for changes and rsyncs
# any files that changed.
#
watch () {
    if ! which fswatch > /dev/null; then
        echo "Installing fswatch"
        brew install fswatch
    fi

    echo "Watching: ${PATHS_TO_SYNC[*]}"

	local exclude_flags
	exclude_flags=$(flags --exclude "$EXCLUDES")

	local fswatch_cmd="fswatch -0 $exclude_flags ${PATHS_TO_SYNC[*]}"

	local file=""
	eval "$fswatch_cmd" | while read -rd "" file
	do
        do_sync "$file" || true
	done
}


usage() {
    echo "Stick it up your ass."
}


#
# This is the business
#
main() {
    local args
    local initial=false
    args=${1:-}
    case $args in
        --*|-*)
            if [[ "$args" = "--initial" || "$args" = "-i" ]]; then
                shift
                initial=true
            else
                usage
                exit 1
            fi
            ;;
        *)
            ;;
    esac
    local paths=(${@:-$(pwd)})

    PATHS_TO_SYNC=()
    for path in "${paths[@]}"; do
        PATHS_TO_SYNC+=($(realpath "$path"))
    done

    # Make sure we do the initial synchronization
    initial_sync

    if [[ "$initial" = true ]]; then
        exit 0
    fi

    # Watch for changes
    watch
}

main "$@"
