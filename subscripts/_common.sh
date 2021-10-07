#!/usr/bin/env bash

### Base functions
function is_mandatory_bin(){
	local bin="${1}"
	if ! command -v "${bin}" &>/dev/null; then
		fatal "${bin} is a mandatory binary, please install it before proceeding."
	fi
}

function is_mandatory_arg(){
	local var="${1}"
	if [ -z "${!var}" ]; then
		fatal "${var} is a mandatory argument"
	fi
}
# Wrapper to print messages
function printmsg(){
	echo -e >&2 "${@}"
}
# Wrapper to print only in verbose mode
function printv(){
	if [ "${verbose}" = "true" ]; then
		printmsg "${@}"
	fi
}
# Print error and exit fatally
function fatal(){
	local with_usage=
	if [ "${1}" = "--usage" ]; then
		with_usage="yes"
		shift
	fi
	printmsg "${@}"
	if [ "${with_usage}" = "yes" ]; then
		printmsg ""
		usage
	fi
	exit 1
}

function read_from_env_or_file(){
	local override_env_file="${SCM_HANDLER_ENV_FILE:-./.env}"
	local variable="${1}"
	local default_value="${2:-}"
	local use_default_first="${3:-no}"
	local retstr=
	if [ "${use_default_first}" = "yes" ] && [ -n "${default_value:-}" ]; then
		echo "${default_value}"
		return
	fi

	if [ -n "${!variable:-}" ]; then
		echo "${!variable}"
	else
		retstr=$(. "${override_env_file}" && echo ${!variable:-})
		if [ -n "${retstr}" ]; then
			echo "${retstr}"
		else
			echo "${default_value}"
		fi
	fi
}

# curl wrapper
function _curlw(){
	local _token="$(read_from_env_or_file PROJECT_SCM_TOKEN_BASE64)"
	local _apiurl="${scm_type}_api_baseurl"
	local outfile="curl_output.log"
	_apiurl=${!_apiurl}

	# Return HTTP code, default to a teapot
	http_code=418

	files_to_remove+=("${outfile}")

	# Token handling depending of SCM API
	case "${scm_type}" in
		gitlab)
			printv curl -sSL -H "PRIVATE-TOKEN: ${_token}" "${@}" "${_apiurl}${curl_request}"
			http_code=$(curl -sSL -H "PRIVATE-TOKEN: $(echo ${_token}|base64 -d)" "${@}" "${_apiurl}${curl_request}" -o "${outfile}" -w '%{http_code}')
			;;
		*)
			printv curl -sSL -u "${scm_username}:${_token}" "${@}" "${_apiurl}${curl_request}"
			http_code=$(curl -sSL -u "${scm_username}:$(echo ${_token}|base64 -d)" "${@}" "${_apiurl}${curl_request}" -o "${outfile}" -w '%{http_code}')
			;;
	esac
	# Some debugging never hurts
	printv "\nHTTP Return code : ${http_code}\n"

	unset -- curl_request
}

# In order not to alter http_code if used in conjuction with curl output
function cat_last_request(){
	local outfile="curl_output.log"
	# Print console output as normal, but store the http_code for further reuse
	cat "${outfile}"
}

function validate_http_code(){
	local expected=${1}
	shift

	if [ "${http_code}" = "${expected}" ]; then
		return
	fi
	printmsg ""
	fatal "${*}"
}

# return whether it is user or organization element
function check_scm_entity(){
	local user_ret="${1:-${scm_username}}"
	local organization_ret="${2:-${scm_organization}}"
	case "${scm_entity,,}" in
		user)
			echo "${user_ret}"
			;;
		organization)
			echo "${organization_ret}"
			;;
		*)
			fatal "unknown entity provided (${scm_entity})"
			;;
	esac
}

# Retrieve appropriate ID according to given entity
function call_appropriate_id(){
	case "${scm_entity,,}" in
		user)
			_get_user_id
			;;
		organization)
			_get_organization_id
			;;
		*)
			fatal "unknown entity provided (${scm_entity})"
			;;
	esac
}

function repository_base_contents(){
	local do_push_branches="${1:-true}"
	local message_name="Automated generation"
	local message_mail="auto.gen@noreply.localhost"
	local clone_baseurl="${scm_type}_clone_baseurl"
	local clone_url="${!clone_baseurl}$(check_scm_entity)/${_reponame}"
	_tmp_dir=$(mktemp -d repository_creation.XXXXXXXX)

	files_to_remove+=("${_tmp_dir}")

	git clone "${clone_url}" "${_tmp_dir}"
	(
		cd "${_tmp_dir}"

		GIT_AUTHOR_NAME="${message_name}"
		GIT_AUTHOR_EMAIL="${message_mail}"
		GIT_COMMITTER_NAME="${message_name}"
		GIT_COMMITTER_EMAIL="${message_mail}"
		export GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL

		cat > README.md <<-EOF
		# ${_reponame}

		TBD
		EOF
		branches_to_push=()
		git checkout -b master
		git add .
		git commit -m "Initial contents"
		if echo "${scm_default_branch}"|grep -qve 'develop\|master'; then
			git checkout -b "${scm_default_branch}"
			branches_to_push+=("${scm_default_branch}")
		fi
		if [ "${scm_create_develop_branch}" = "true" ]; then
			git checkout -b develop
			branches_to_push+=("develop")
		fi
		branches_to_push+=("master")
		if [ "${do_push_branches}" = "true" ]; then
			git push origin "${branches_to_push[@]}"
		fi
		unset -- branches_to_push GIT_COMMITTER_EMAIL GIT_COMMITTER_NAME GIT_AUTHOR_EMAIL GIT_AUTHOR_NAME
	)
}

function prompt_for_removal_ok(){
	local answer=
	local ret=
	if [ "${force_removal}" ]; then
		return
	fi

	read -r -p "Are you sure you want to remove '${_reponame}' ? (yes/NO) " answer
	if [ "${answer,,}" != "yes" ]; then
		printmsg "Skipping the removal"
		return 1
	fi
}

#END
