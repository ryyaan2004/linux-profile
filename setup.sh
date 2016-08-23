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
	sed -i -e "s/${2}//" ${1}
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
	sed -i -e "/${2}/,/${3}/c\ " ${1}
}

# TODO: put these in a .properties file
#BOUNDARY="#|-|-|-|#"
#HEADER="${BOUNDARY} profile setup header ${BOUNDARY}"
#FOOTER="${BOUNDARY} profile setup footer ${BOUNDARY}"

#PROFILE=""
#EXISTY=0
#HEADER_EXISTS=5
#FOOTER_EXISTS=5

#COPY_CONF_TO="$(pwd)/tmp"
#COPY_BIN_TO="$(pwd)/tmp/bin"
if [ -f "./profile.properties" ]
then
	. ./profile.properties
else
	printf "error: missing properties file\n"
	exit 1
fi

CONF_ARR=()
BIN_ARR=()

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
test_for_line "${PROFILE}" "^${FOOTER}$"
FOOTER_EXISTS=$?
echo "FOOTER_EXISTS=${FOOTER_EXISTS}"

# since the profile can get into inconsistent states, ensure that we can work with what's there
if [ "${HEADER_EXISTS}" -eq "${EXISTY}" ] && [ "${FOOTER_EXISTS}" -eq "${EXISTY}" ]
then
	printf "this should be true, both exist\n"
	remove_all_lines_in_range "${PROFILE}" "${HEADER}" "${FOOTER}"
elif [ "${FOOTER_EXISTS}" -eq "${EXISTY}" ]
then
	printf "existing profile in incompatible state, only the footer exists. please remove '${FOOTER}' and all managed data then rerun this script\n"
	exit 1
else
	printf "existing profile in incompatible state, only the header exists. please remove '${HEADER}' and all managed data then rerun this script\n"
fi
# TODO insert the header, all settings, and the footer
#append_string_to_file "${PROFILE}" "${HEADER}"
#append_string_to_file "${PROFILE}" "this is where we would insert stuff\n"
#append_string_to_file "${PROFILE}" "seriously, in a live situation there would be stuff around this area\n"
#append_string_to_file "${PROFILE}" "\n\n"
#append_string_to_file "${PROFILE}" "${FOOTER}"

i=0
# copy all from workspace/conf to HOME
for file in $( ls -A conf/ )
do
	CONF_ARR[$i]="${COPY_CONF_TO}/${file}"
	cp "$(pwd)/conf/${file}" ${CONF_ARR[$i]} #"${COPY_CONF_TO}/${file}"
	(( i++ ))
done

i=0
# copy all from workspace/bin to HOME/bin
for file in $( ls -A bin/ )
do
	BIN_ARR[$i]="${COPY_BIN_TO}/${file}"
	cp "$(pwd)/bin/${file}" ${BIN_ARR[$i]} #"${COPY_BIN_TO}/${file}"
done

# append header
append_string_to_file "${PROFILE}" "${HEADER}"

# append entries to source all newly copied files
for entry in ${CONF_ARR[*]}
do
	append_string_to_file "${PROFILE}" ". ${entry}"
done

for entry in ${BIN_ARR[*]}
do
	append_string_to_file "${PROFILE}" ". ${entry}"
done

# append footer
append_string_to_file "${PROFILE}" "${FOOTER}"
