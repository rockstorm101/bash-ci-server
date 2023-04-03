#!/usr/bin/env bash

set -euo pipefail

if [ -n "${DEBUG-}" ]; then set -x; fi

warn() { echo "warning:" "$@" >&2; }
log() {
    # Use same logging as the Bash CI scripts for consistency
    "${BASH_CI_DIR}"/git.bash log "$@"
}

cleanup() {
    rm -rf "${job_dir-}"
}

generate_job() {
    # This function will always return zero
    trap 'exit_status=2; cleanup; return 0' ERR

    local repo_id=${1} url=${2} sha=${3} ref=${4}

    hooks_file="$HOOKS_DIR"/"$repo_id"/hooks.ltsv
    if [ ! -f "$hooks_file" ]; then
        exit_status=1;
        warn "Hook file '$hooks_file' could not be located"
        return 0
    fi

    log_dir="$LOGS_DIR"/"$repo_id"
    mkdir -p "$log_dir"

    # This ID differs from the one assigned by Bash CI which is
    # unknown at this stage of the execution. It is only used to
    # generate the temporary file to execute the job
    job_id=$(date -u +%y%m%d%H%M%S)
    job_dir="${JOBS_DIR-/tmp/jobs}"/"$repo_id"/$job_id
    mkdir -p "$job_dir"

    cd "$job_dir"
    if ! env GIT_TERMINAL_PROMPT=0 git clone "$url" . 2>&1; then
        exit_status=1
        warn "Could not get repository at URL '$url'"
        cleanup
        return 0
    fi
    git checkout -q "$sha"
    rm -rf .git .gitignore

    if ! echo -e "${sha}\t${ref}" | \
            bash "${BASH_CI_DIR}"/git.bash hook_push \
                 --logdir "$log_dir" --hooks "$hooks_file"; then
        exit_status=1
        return 0
	fi
}


# Start ncat server
log "Server listening on port ${SERVER_PORT}"
exit_status=0
while read -r repo_id url sha ref; do
    log "Notification received:"
    echo "ID: $repo_id, URL: $url" >&2
    echo "Commit: $sha, Ref: $ref" >&2

    generate_job "$repo_id" "$url" "$sha" "$ref"

    case $exit_status in
        0 | 1) # success or "minor" error
            continue ;;
        2) log "Fatal error. Server terminated."
            break ;;
        *) log "Unexpected error occurred. Server terminated."
            break ;;
    esac

done < <(ncat -l -k -p "${SERVER_PORT}")

# Kill hanging ncat process
kill -TERM $! 2>/dev/null
