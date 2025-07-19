#!/bin/bash

# Cross-platform sed -i function
function sed_inplace() {
# $1 the file to modify
# $2 the sed expression
	local file="${1}"
	local expr="${2}"
	
	if [[ "$OSTYPE" == "darwin"* ]]; then
		sed -i '' -e "${expr}" "${file}"
	else
		sed -i -e "${expr}" "${file}"
	fi
}

function append_string_to_file() {
# $1 the file to append to
# $2 the message to append
	if [ ! -f "${1}" ]
	then
		echo "There was a problem writing to '${1}'"
		exit 1
	fi

	local file="${1}"
	local msg="${2}"
	echo "${msg}" >> "${file}"
}

function test_for_line() {
# $1 the file to test
# $2 the line to test for
	if [ ! -f "${1}" ]
	then
		echo "There was a problem reading file '${1}'"
		exit 1
	fi
	local existy
	existy=$(grep -x "${2}" "${1}")
	if [ -z "${existy}" ]
	then
		return 1
	else
		return 0
	fi
}

function remove_single_line_from_file() {
# $1 the file to remove from
# $2 the string to delete
	if [ ! -f "${1}" ]
	then
		echo "There was a problem opening the file for modification '${1}'"
		exit 1
	fi
	sed_inplace "${1}" "s/${2}//"
}

function remove_all_lines_in_range() {
# $1 the file
# $2 the starting pattern
# $3 the ending pattern
	if [ ! -f "${1}" ]
	then
		echo "There was a problem opening the file for modification '${1}'"
		exit 1
	fi
	sed_inplace "${1}" "/${2}/,/${3}/c\ "
}

if [ -f "./profile.properties" ]
then
	. ./profile.properties
else
	printf "error: missing properties file\n"
	exit 1
fi

CONF_ARR=()
BIN_ARR=()

# check for the profile
if [ -f "$HOME/.profile" ]
then
	PROFILE="$HOME/.profile"
elif [ -f "$HOME/.bash_profile" ]
then
	PROFILE="$HOME/.bash_profile"
fi

if [ -f "${PROFILE}" ]
then
	cp "${PROFILE}" "${PROFILE}.bak"
else
	printf "Could not locate a profile"
	exit 1
fi

test_for_line "${PROFILE}" "^${HEADER}$"
HEADER_EXISTS=$?

test_for_line "${PROFILE}" "^${FOOTER}$"
FOOTER_EXISTS=$?

# since the profile can get into inconsistent states, ensure that we can work with what's there
if [ "${HEADER_EXISTS}" -eq 0 ] && [ "${FOOTER_EXISTS}" -eq 0 ]
then
	remove_all_lines_in_range "${PROFILE}" "${HEADER}" "${FOOTER}"
elif [ "${FOOTER_EXISTS}" -eq 0 ]
then
	printf "existing profile in incompatible state, only the footer exists. please remove '%s' and all managed data then rerun this script\n" "${FOOTER}"
	exit 1
elif [ "${HEADER_EXISTS}" -eq 0 ]
then
	printf "existing profile in incompatible state, only the header exists. please remove '%s' and all managed data then rerun this script\n" "${HEADER}"
	exit 1
else
	: 
fi

i=0
# copy all from workspace/conf to HOME
while IFS= read -r -d '' filepath; do
	file=$(basename "$filepath")
	CONF_ARR[i]="${COPY_CONF_TO}/${file}"
	cp "$filepath" "${CONF_ARR[$i]}"
	(( i++ ))
done < <(find conf/ -maxdepth 1 -type f -print0)

# Ensure target directories exist
mkdir -p "${COPY_BIN_TO}"

i=0
# copy all from workspace/bin to HOME/bin
while IFS= read -r -d '' filepath; do
	file=$(basename "$filepath")
	BIN_ARR[i]="${COPY_BIN_TO}/${file}"
	cp "$filepath" "${BIN_ARR[$i]}"
	(( i++ ))
done < <(find bin/ -maxdepth 1 -type f -print0)

# append header
append_string_to_file "${PROFILE}" "${HEADER}"

# append entries to source all newly copied files
for entry in "${CONF_ARR[@]}"
do
	filename=$(basename "${entry}")
	if [[ "${EXCLUSIONS}" =~ ${filename} ]]
	then
		:
	else
		append_string_to_file "${PROFILE}" ". \"${entry}\""
	fi
done

for entry in "${BIN_ARR[@]}"
do
	filename=$(basename "${entry}")
	if [[ "${EXCLUSIONS}" =~ ${filename} ]]
	then
		:
	else
		append_string_to_file "${PROFILE}" ". \"${entry}\""
	fi
done

# append footer
append_string_to_file "${PROFILE}" "${FOOTER}"

# source the profile
source "${PROFILE}"
