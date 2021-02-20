#!/usr/bin/env bash
# Author: PsykoCat
# Source: github:psykocat/scm-repository-handler
# License: Apache 2.0 License

set -eu

### Global variables definition
__VERSION__=0.0.1

## For dynamic calling
_sub_method=
_method=
###

### Inner working global variables (should not be tinkered)
verbose=
declare -a files_to_remove=()
declare do_not_remove_files=
readonly script_dir="$(dirname $(readlink -f "${BASH_SOURCE[0]}" ))"
###

# Cleanup process if needed, by default does nothing
function cleanup(){
	# Remove intermediary branded files if not specified otherwise
	if [ "${do_not_remove_files}" = "yes" ]; then
		return
	fi
	if [ ${#files_to_remove[@]} -gt 0 ]; then
		rm -${verbose:+v}rf -- "${files_to_remove[@]}"
	fi
}
# trap -l to list all signals, write them without the SIG part
trap cleanup EXIT
###

### Common functions
. "${script_dir}/_common.sh"
###

### Common functions
. "${script_dir}/_options_and_usage.sh"
###

if echo $-|grep -qe 'x'; then
	do_not_remove_files="yes"
fi

if [ "${print_version}" = "yes" ]; then
	printmsg "${0} : ${__VERSION__:-0.0.0}";
	exit 0;
fi

# Format action to match method name
action=${action//-/_};

scm_type=$(read_from_env_or_file PROJECT_SCM_TYPE "${scm_type}")
scm_organization=$(read_from_env_or_file PROJECT_SCM_ORGANIZATION "${scm_organization}")
scm_username=$(read_from_env_or_file PROJECT_SCM_USER)
scm_default_branch=$(read_from_env_or_file SCM_DEFAULT_BRANCH "master")
scm_create_develop_branch=$(read_from_env_or_file SCM_CREATE_DEVELOP_BRANCH "true")

## Mandatory element check

is_mandatory_bin curl
is_mandatory_bin jq

is_mandatory_arg action
is_mandatory_arg scm_type
is_mandatory_arg scm_username
if [ "${scm_entity}" = "organization" ]; then
	is_mandatory_arg scm_organization
fi

# load associated methods
. "${script_dir}/_${scm_type}_functions.sh"

is_mandatory_arg "${scm_type}_api_baseurl"
is_mandatory_arg "${scm_type}_clone_baseurl"

_sub_method="${action}_repo"
_method="${scm_type}_${_sub_method}"

# In case of some scm types having custom mandatory needs
precheck_method="_${scm_type}_pre_check"
if declare -F "${precheck_method}" &>/dev/null; then
	"${precheck_method}"
fi

if [ "${action}" = "list" ]; then
	"${_method}"
else
	for _reponame in "${args[@]}"; do
		"${_method}" "${_reponame}"
	done
	unset -- _reponame
fi

# vim: noexpandtab:
