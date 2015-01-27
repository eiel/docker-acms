#!/bin/bash
set -e

if [ -z "$MYSQL_PORT_3306_TCP" ]; then
	echo >&2 'error: missing MYSQL_PORT_3306_TCP environment variable'
	echo >&2 '  Did you forget to --link some_mysql_container:mysql ?'
	exit 1
fi

# if we're linked to MySQL, and we're using the root user, and our linked
# container has a default "root" password set up and passed through... :)
: ${ACMS_DB_USER:=root}
if [ "$ACMS_DB_USER" = 'root' ]; then
	: ${ACMS_DB_PASSWORD:=$MYSQL_ENV_MYSQL_ROOT_PASSWORD}
fi
: ${ACMS_DB_NAME:=acms}

if [ -z "$ACMS_DB_PASSWORD" ]; then
	echo >&2 'error: missing required ACMS_DB_PASSWORD environment variable'
	echo >&2 '  Did you forget to -e ACMS_DB_PASSWORD=... ?'
	echo >&2
	echo >&2 '  (Also of interest might be ACMS_DB_USER and ACMS_DB_NAME.)'
	exit 1
fi

if ! [ -e index.php -a -e wp-includes/version.php ]; then
	echo >&2 "acms not found in $(pwd) - copying now..."
	if [ "$(ls -A)" ]; then
		echo >&2 "WARNING: $(pwd) is not empty - press Ctrl+C now if this is an error!"
		( set -x; ls -A; sleep 10 )
	fi
	rsync --archive --one-file-system --quiet /usr/src/acms/ .
	if ! [ -e _setup ]; then
		rsync --archive --one-file-system --quiet /usr/src/acms_setup/ setup
	fi
	echo >&2 "Complete! acms has been successfully copied to $(pwd)"
fi

ACMS_DB_HOST=mysql

TERM=dumb php -- "$ACMS_DB_HOST" "$ACMS_DB_USER" "$ACMS_DB_PASSWORD" "$ACMS_DB_NAME" <<'EOPHP'
<?php
// database might not exist, so let's try creating it (just to be safe)
$stderr = fopen('php://stderr', 'w');
list($host, $port) = explode(':', $argv[1], 2);
$maxTries = 10;
do {
	$mysql = new mysqli($host, $argv[2], $argv[3], '', (int)$port);
	if ($mysql->connect_error) {
		fwrite($stderr, "\n" . 'MySQL Connection Error: (' . $mysql->connect_errno . ') ' . $mysql->connect_error . "\n");
		--$maxTries;
		if ($maxTries <= 0) {
			exit(1);
		}
		sleep(3);
	}
} while ($mysql->connect_error);
if (!$mysql->query('CREATE DATABASE IF NOT EXISTS `' . $mysql->real_escape_string($argv[4]) . '` DEFAULT CHARACTER SET utf8 COLLATE utf8_bin')) {
	fwrite($stderr, "\n" . 'MySQL "CREATE DATABASE" Error: ' . $mysql->error . "\n");
	$mysql->close();
	exit(1);
}
$mysql->close();
EOPHP

chown -R apache:apache .

exec "$@"
