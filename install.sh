#!/bin/bash

# MC Server for Linux installation script
# See https://www.minhaconexao.com.br/perguntas-frequentes/instalacao-servidor-testes for the installation steps.

set -e

SERVER_VERSION="3.0.3"
SCRIPT_BUCKET="https://mc-server-scripts.s3-sa-east-1.amazonaws.com"
SERVER_BUCKET="https://server-deploys.s3-sa-east-1.amazonaws.com"
TMP_DIR=$(mktemp -d)
WORKDIR="mc-test"
BIN="mc-test"

ARCHITECTURE_FOLDER=''
if [ "$(uname -m)" == 'x86_64' ]; then
	ARCHITECTURE_FOLDER='x64'
else
	ARCHITECTURE_FOLDER='x32'
fi

OS_NAME=$(cat /etc/os-release | awk -F '=' '/^NAME/{print $2}' | awk '{print $1}' | tr -d '"')
if [ "$OS_NAME" == "CentOS" ] || [ "$OS_NAME" == "Fedora" ] || [ "$OS_NAME" == "Red" ]; then
	OS_FAMILY="centoslike"
else
	OS_FAMILY="debianlike"
fi

log_info() {
	echo "$1"
	logdir="$TMP_DIR/logs"
	if ! [ -d "$logdir" ]; then
		mkdir -p "$logdir"
		touch "$logdir/output.txt"
	fi
	d=$(date +"%Y-%m-%d %T")
	echo "[$d] [INFO] $1" >> "$logdir/output.txt"
}

log_fatal() {
	echo "$1" 1>&2
	exit 1
}

download() {
	url=$1
	out=$2
	wget -q -O "$out" "$url"
	log_info "Download file $url -> OK"
}

check_root() {
	if [ "$(id -u)" != "0" ]; then
		log_fatal "Please, run the script as root"
	fi
	log_info "Check root -> OK"
}

check_arch() {
	if [ "$ARCHITECTURE_FOLDER" != "x64" ]; then
		log_fatal "System must be x64"
	fi
	log_info "Check architecture -> OK"
}

check_wget() {
	if ! [ -x "$(command -v wget)" ]; then
		log_fatal "Wget not found, please install";
	fi
	log_info "Check wget -> Ok"
}

create_initial_structure() {
	cd "$TMP_DIR"
	log_info "Create Initial Structure -> OK"
}

delete_tmp_structure() {
	log_info "Deleting temp structure -> OK"
	rm -rf "$TMP_DIR"
}

download_certificates_files() {
	mkdir -p keys
	download "$SCRIPT_BUCKET/certs/star.mcservers.co.crt" "keys/star.mcservers.co.crt"
	download "$SCRIPT_BUCKET/certs/full-cert.pfx" "keys/full-cert.pfx"
	log_info "Download Certificate Files -> OK"
}

download_test_server() {
	download "$SERVER_BUCKET/mc-server-v$SERVER_VERSION/target/release/mc-server" "$BIN"
	if [ "$OS_FAMILY" == "centoslike" ]; then
		download "$SCRIPT_BUCKET/$SERVER_VERSION/services/centos/mc-test.sh" "$BIN.sh"
		download "$SCRIPT_BUCKET/$SERVER_VERSION/services/centos/mc-test.service" "$BIN.service"
		chmod 755 "$BIN.sh"
	else
		download "$SCRIPT_BUCKET/$SERVER_VERSION/services/debian/mc-test.service" "$BIN.service"
	fi
	chmod 755 $BIN
	chmod 755 "$BIN.service"
	log_info "Download Test Server Files -> OK"
}

delete_old_files() {
	log_info "Deleting old files"
	rm -rf "/etc/$WORKDIR/public"
	rm -rf "/etc/$WORKDIR/keys"
	rm -f "/etc/$WORKDIR/$BIN"
	rm -f "/etc/$WORKDIR/updater"
	rm -f "/etc/systemd/system/$BIN.service"
	rm -f "/etc/systemd/system/$BIN"
	rm -f "/usr/local/bin/$BIN"
	rm -f "/usr/local/bin/$BIN.sh"
	rm -f "/usr/bin/$BIN"
	log_info "Delete Old Files -> OK"
}

move_test_server_files() {
	mkdir -p "/etc/$WORKDIR"
	mv "$BIN" "/etc/$WORKDIR/$BIN"
	mv keys "/etc/$WORKDIR/"

	if [ "$OS_FAMILY" == "centoslike" ]; then
		mv "$BIN.sh" /usr/local/bin
		ln -s "/etc/$WORKDIR/$BIN" "/usr/local/bin/$BIN"
		log_info "Create symbolic link to $BIN -> OK"
		bash -c "cat $BIN.service > /etc/systemd/system/$BIN.service"
		log_info "Move service file to CentOSLike folder -> OK"
	else
		ln -s "/etc/$WORKDIR/$BIN" "/usr/bin/$BIN"
		log_info "Create symbolic link to $BIN -> OK"
		mv "$BIN.service" /etc/systemd/system
		log_info "Move service file to systemd folder -> OK"
	fi
}

move_logs() {
	log_info "Moving logs -> OK"
	mv logs "/etc/$WORKDIR/logs"
}

do_install() {
	log_info "Installing MC Server v$SERVER_VERSION - $ARCHITECTURE_FOLDER..."
	check_root
	check_arch
	check_wget
	create_initial_structure
	download_certificates_files
	download_test_server
	delete_old_files
	move_test_server_files
	log_info "Successfully installed!"
	move_logs
	delete_tmp_structure
}

do_install
