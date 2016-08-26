#!/usr/bin/env bash

if [ $# -lt 3 ]; then
	echo "usage: $0 <db-name> <db-user> <db-pass> [db-host] [wp-version]"
	exit 1
fi

TESTS_ROOT_DIR=$(pwd)
DB_NAME=$1
DB_USER=$2
DB_PASS=$3
DB_HOST=${4-localhost}
WP_VERSION=${5-latest}

download() {
    if [ `which curl` ]; then
        curl -s "$1" > "$2";
    elif [ `which wget` ]; then
        wget -nv -O "$2" "$1"
    fi
}

if [[ $WP_VERSION =~ [0-9]+\.[0-9]+(\.[0-9]+)? ]]; then
	WP_TESTS_TAG="tags/$WP_VERSION"
else
	# http serves a single offer, whereas https serves multiple. we only want one
	download http://api.wordpress.org/core/version-check/1.7/ /tmp/wp-latest.json
	grep '[0-9]+\.[0-9]+(\.[0-9]+)?' /tmp/wp-latest.json
	LATEST_VERSION=$(grep -o '"version":"[^"]*' /tmp/wp-latest.json | sed 's/"version":"//')
	if [[ -z "$LATEST_VERSION" ]]; then
		echo "Latest WordPress version could not be found"
		exit 1
	fi
	WP_TESTS_TAG="tags/$LATEST_VERSION"
fi

set -ex

install_db() {
	# parse DB_HOST for port or socket references
	local PARTS=(${DB_HOST//\:/ })
	local DB_HOSTNAME=${PARTS[0]};
	local DB_SOCK_OR_PORT=${PARTS[1]};
	local EXTRA=""

	if ! [ -z $DB_HOSTNAME ] ; then
		if [ $(echo $DB_SOCK_OR_PORT | grep -e '^[0-9]\{1,\}$') ]; then
			EXTRA=" --host=$DB_HOSTNAME --port=$DB_SOCK_OR_PORT --protocol=tcp"
		elif ! [ -z $DB_SOCK_OR_PORT ] ; then
			EXTRA=" --socket=$DB_SOCK_OR_PORT"
		elif ! [ -z $DB_HOSTNAME ] ; then
			EXTRA=" --host=$DB_HOSTNAME --protocol=tcp"
		fi
	fi

	# create database
	mysqladmin create $DB_NAME --user="$DB_USER" --password="$DB_PASS"$EXTRA
}

install_test_suite() {
  if [ -d ${TESTS_ROOT_DIR}/tests ]; then
    rm -fr ${TESTS_ROOT_DIR}/tests
	fi

  mkdir -p ${TESTS_ROOT_DIR}/tests
  svn co --quiet https://develop.svn.wordpress.org/${WP_TESTS_TAG}/ ${TESTS_ROOT_DIR}/tests

	cd ${TESTS_ROOT_DIR}/tests

	if [[ $(uname -s) == 'Darwin' ]]; then
		local ioption='-i .bak'
	else
		local ioption='-i'
	fi

	if [ ! -f wp-tests-config.php ]; then
		cp ${TESTS_ROOT_DIR}/tests/wp-tests-config-sample.php ${TESTS_ROOT_DIR}/tests/wp-tests-config.php
		sed $ioption "s/youremptytestdbnamehere/$DB_NAME/" ${TESTS_ROOT_DIR}/tests/wp-tests-config.php
		sed $ioption "s/yourusernamehere/$DB_USER/" ${TESTS_ROOT_DIR}/tests/wp-tests-config.php
		sed $ioption "s/yourpasswordhere/$DB_PASS/" ${TESTS_ROOT_DIR}/tests/wp-tests-config.php
		sed $ioption "s/yourpasswordhere/$DB_PASS/" ${TESTS_ROOT_DIR}/tests/wp-tests-config.php
		sed $ioption "s|localhost|${DB_HOST}|" ${TESTS_ROOT_DIR}/tests/wp-tests-config.php
	fi
}

install_test_suite
install_db
