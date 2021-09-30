#!/usr/bin/env bash

function _get_user_id(){
	local curl_request="/user"
	_curlw -X GET
	validate_http_code "200" "Error while fetching user id"
	cat_last_request|jq -r '.id'
}

function _get_organization_id(){
	local curl_request="/groups/${scm_organization}"
	_curlw -X GET
	validate_http_code "200" "Error while fetching user id"
	cat_last_request|jq -r '.id'
}

function _get_project_id(){
	local _project="${1}"
	local curl_request="/projects?membership=true&search=${_project}"

	_curlw -X GET
	validate_http_code 200 "Error while fetching project id"
	cat_last_request|jq -r '.[0].id'
}

# Look for API base url, default to the public official one, if any
gitlab_api_baseurl="$(read_from_env_or_file GITLAB_API_BASEURL)"
gitlab_clone_baseurl="$(read_from_env_or_file GITLAB_CLONE_BASEURL)"
function gitlab_create_repo(){
	# TODO: Validate it works for groups
	local curl_request="$(check_scm_entity /projects /projects)"
	local id_field="$(check_scm_entity user_id namespace_id)"
	local __userid=$(call_appropriate_id)
	if [ "${__userid}" = "null" ] || [ -z "${__userid}" ]; then
		fatal "Wrong user id, aborting. (${__userid} found)"
	fi
	cat > data.json <<-EOF
	{
		"name": "${_reponame}",
		"${id_field}": ${__userid},
		"visibility": "${visibility}"
	}
	EOF
	files_to_remove+=("data.json")
	_curlw -X POST --header "Content-Type: application/json" --data "@data.json"
	validate_http_code 201 "Error while creating ${_reponame} !"

	if [ "${create_base_repository}" = "true" ]; then
		repository_base_contents
		${scm_type}_set_default_branch_repo
	fi
}

function gitlab_delete_repo(){
	local __projectid=$(_get_project_id ${_reponame})
	if [ "${__projectid}" = "null" ]; then
		fatal "Error while fetching project id"
	fi
	local curl_request="/projects/${__projectid}"
	if prompt_for_removal_ok; then
		_curlw -X DELETE
		validate_http_code 202 "Error while deleting ${_reponame}"
	fi
}

function gitlab_list_repo(){
	local curl_request="$(check_scm_entity /users/${scm_username}/projects /groups/${scm_organization}/projects)"
	_curlw -X GET --header "Content-Type: application/json"
	validate_http_code 200 "Error while listing repositories"
	cat_last_request | jq -r '.[].path'
}

function gitlab_set_default_branch_repo(){
	local project_id=$(_get_project_id ${_reponame})
	local curl_request="/projects/${project_id}"

	cat > data.json <<-EOF
	{
		"id": "${project_id}",
		"default_branch": "${scm_default_branch}"
	}
	EOF
	files_to_remove+=("data.json")
	_curlw -X PUT --header "Content-Type: application/json" --data "@data.json"
	validate_http_code 200 "Error while setting default branch"
}

#END
