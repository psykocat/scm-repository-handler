#!/usr/bin/env bash
set -eu

function usage(){
	cat > /dev/stderr <<-EOF
	usage: ${0} [options] [repository...]

	optional arguments:
	  -h, --help            show this help message and exit
	  -f, --force           Force without prompting
	  -v, --verbose         Verbose mode
	  --version             Show version and exit
	  --create, --delete, --list, --set-default-branch
	                        Action to perform
	  --github, --gitlab, --bitbucket
	                        Targeted SCM for rest API
	  --private, --public, --internal
	                        Visibility of the repository
	  --org                 Organization, group or teams associated to process
	  --base-repo           Create base repository
	  --user, --organization
	                        Whether to act as user or organization level
	EOF
}

force_removal=""
verbose=""
print_version=""
action=""
scm_type=""
visibility=""
scm_organization=""
create_base_repository=""
scm_entity=""
declare -a args=()

while [ $# -ne 0 ]; do
	case "${1,,}" in
		--) shift; break;;
		-h|-help|--help) usage; exit 1;;
		--debug) set -x;;
		-f|--force) force_removal="true";;
		-v|--verbose) verbose="true";;
		--version) print_version="true";;
		--create|--delete|--list|--set-default-branch) action="${1#--}";;
		--github|--gitlab|--bitbucket) scm_type="${1#--}";;
		--private|--public|--internal) visibility="${1#--}";;
		--org) scm_organization="true";;
		--base-repo) create_base_repository="true";;
		--user|--organization) scm_entity="${1#--}";;
		*) args+=("${1}");;
	esac
	shift;
done

#END
