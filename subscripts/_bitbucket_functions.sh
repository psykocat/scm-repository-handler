#!/usr/bin/env bash

function _get_user_id(){
	local curl_request="/user"
	_curlw -X GET --header "Content-Type: application/json"
	cat_last_request|jq -r '.'
}

function _get_project_id(){
	local _project="${1}"
	local curl_request="/projects?membership=true&search=${_project}"

	_curlw -X GET --header "Content-Type: application/json"
	cat_last_request|jq -r '.[0].id'
}

# Look for API base url, default to the public official one, if any
bitbucket_api_baseurl="$(read_from_env_or_file BITBUCKET_API_BASEURL)"
bitbucket_clone_baseurl="$(read_from_env_or_file BITBUCKET_CLONE_BASEURL)"

function bitbucket_create_repo(){
	# TODO: Validate it works for groups
	local curl_request="/repositories/$(check_scm_entity)/${_reponame}"
	local is_private=
	local -a branches_to_push=()

	if [ "${visibility}" = "public" ]; then
		is_private="false"
	else
		is_private="true"
	fi

	cat > data.json <<-EOF
	{
		"scm": "git",
		"forkable": false,
		"is_private": ${is_private},
		"description": ""
	}
	EOF
	files_to_remove+=("data.json")
	_curlw -X PUT --header "Content-Type: application/json" --data "@data.json"
	#validate_http_code 201 "Error while creating ${_reponame} !"

	if [ "${create_base_repository}" = "true" ]; then
		repository_base_contents "false"
		if echo "${scm_default_branch}"|grep -qve 'develop\|master'; then
			branches_to_push+=("${scm_default_branch}")
		fi
		if [ "${scm_create_develop_branch}" = "true" ]; then
			branches_to_push+=("develop")
		fi
		branches_to_push+=("master")
		(
			cd "${_tmp_dir}"
			echo "Pushing branch one at a time to set properly the first default branch"
			for _branch in "${branches_to_push[@]}"; do
				git push origin "${_branch}"
			done
		)
	fi
}

function bitbucket_delete_repo(){
	local curl_request="/repositories/$(check_scm_entity)/${_reponame}"
	if prompt_for_removal_ok; then
		_curlw -X DELETE --header "Content-Type: application/json"
		#validate_http_code 202 "Error while deleting ${_reponame}"
	fi
}

function bitbucket_list_repo(){
	local curl_request="/repositories/$(check_scm_entity)"
	_curlw -X GET --header "Content-Type: application/json"
	cat_last_request|jq -r '.values[].slug'
}

function bitbucket_set_default_branch_repo(){
	printmsg "Main branch can be set only at creation of the repositoryfor bitbucket 2.0 at the moment..."
}

#END
