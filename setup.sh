#!/bin/bash

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
	echo "${msg}" >> ${file}
}

function test_for_line() {
# $1 the file to test
# $2 the line to test for
	if [ ! -f "${1}" ]
	then
		echo "There was a problem reading file '${1}'"
		exit 1
	fi
	local existy=$(grep -x "${2}" "${1}")
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
	sed --quiet "s/${2}//" ${1}
}

BOUNDARY="#-/-/-/#"
HEADER="${BOUNDARY} profile setup header ${BOUNDARY}"
FOOTER="${BOUNDARY} profile setup footer ${BOUNDARY}"

PROFILE=""
HEADER_EXISTS=5
FOOTER_EXISTS=5

PROFILE="$(pwd)/profile"
if [ ! -f "${PROFILE}" ]
then
	touch "${PROFILE}"
	append_string_to_file "${PROFILE}" "${HEADER}"
	append_string_to_file "${PROFILE}" "this is a test message"
	append_string_to_file "${PROFILE}" "${FOOTER}"
fi
#if [ -f "$HOME/.profile" ]
#then
#	PROFILE="$HOME/.profile"
#elif [ -f "$HOME/.bash_profile" ]
#then
#	PROFILE="$HOME/.bash_profile"
#fi

echo "profile='${PROFILE}'"

test_for_line "${PROFILE}" "^${HEADER}$"
HEADER_EXISTS=$?
echo "HEADER_EXISTS=${HEADER_EXISTS}"
test_for_line "${PROFILE}" "${FOOTER}"
FOOTER_EXISTS=$?
echo "FOOTER_EXISTS=${FOOTER_EXISTS}"

# insert the header and footer as necessary

