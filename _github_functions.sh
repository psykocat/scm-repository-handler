#!/usr/bin/env bash

# Look for API base url, default to the public official one, if any
github_api_baseurl="$(read_from_env_or_file GITHUB_API_BASEURL)"
github_clone_baseurl="$(read_from_env_or_file GITHUB_CLONE_BASEURL)"
function github_create_repo(){
	local curl_request="$(check_scm_entity /user/repos /orgs/${scm_organization}/repos)"
	local is_private=
	if [ "${visibility}" = "public" ]; then
		is_private="false"
	else
		is_private="true"
	fi
	cat > data.json <<-EOF
	{
		"name": "${_reponame}",
		"private": ${is_private}
	}
	EOF
	files_to_remove+=("data.json")
	_curlw -X POST -H "Accept: application/vnd.github.v3+json" --data "@data.json"
	validate_http_code 201 "Could not create repository"

	if [ "${create_base_repository}" = "true" ]; then
		repository_base_contents
		${scm_type}_set_default_branch_repo
	fi
}

function github_delete_repo(){
	local curl_request="$(check_scm_entity /repos/${scm_username}/${_reponame} /repos/${scm_organization}/${_reponame})"
	if prompt_for_removal_ok; then
		_curlw -X DELETE -H "Accept: application/vnd.github.v3+json"
		validate_http_code 204 "Could not delete repository"
	fi
}

function github_list_repo(){
	local curl_request="$(check_scm_entity /user/repos /orgs/${scm_organization}/repos)"
	_curlw -X GET -H "Accept: application/vnd.github.v3+json"
	validate_http_code 200 "Could not list repositories"
	cat_last_request|jq -r '.[].name'
}

function github_set_default_branch_repo(){
	local curl_request="$(check_scm_entity /repos/${scm_username}/${_reponame} /repos/${scm_organization}/${_reponame})"
	cat > data.json <<-EOF
	{
		"name": "${_reponame}",
		"default_branch": "${scm_default_branch}"
	}
	EOF
	files_to_remove+=("data.json")
	_curlw -X PATCH -H "Accept: application/vnd.github.v3+json" --data "@data.json"
	validate_http_code 200 "Could not set default branch properly"
}

#END
