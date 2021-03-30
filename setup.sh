#!/bin/bash
. static/menu.sh
source $CWD\.env


#https://bytefreaks.net/gnulinux/bash/cecho-a-function-to-print-using-different-colors-in-bash
cecho () {
	declare -A colors;
	colors=(\
		['black']='\E[0;47m'\
		['red']='\E[0;31m'\
		['green']='\E[0;32m'\
		['yellow']='\E[0;33m'\
		['blue']='\E[0;34m'\
		['magenta']='\E[0;35m'\
		['cyan']='\E[0;36m'\
		['white']='\E[0;37m'\
		);



	local defaultMSG="";
	local defaultColor="black";
	local defaultNewLine=true;



	while [[ $# -gt 1 ]];
	do
		key="$1";



		case $key in
			-c|--color)
				color="$2";
				shift;
				;;

			-n|--noline)
				newLine=false;
				;;
			*)
				# unknown option
				;;
		esac
		shift;
	done

	message=${1:-$defaultMSG};   # Defaults to default message.
	color=${color:-$defaultColor};   # Defaults to default color, if not specified.
	newLine=${newLine:-$defaultNewLine};

	echo -en "${colors[$color]}";
	echo -en "$message";
	if [ "$newLine" = true ] ; then
		echo;
	fi
	tput sgr0; #  Reset text attributes to normal without clearing screen.
	return;
}


function wizzard {
	#cecho -c 'blue' "$@";
	ui_widget_select -l -k "${!menu[@]}" -s bar -i "${menu[@]}"
}

function editVariable(){
	if [ "$1" == "" ]; then
		read -p "Please set a config value for $3 [$2]: " VALUE
		VALUE="${VALUE:-$2}"
		sed -i "s@$3=.*@$3=\"$VALUE\"@g" .env
	fi
}
function setConfig(){
	editVariable "$DOMAIN" "localhost" "DOMAIN"
	editVariable "$SERVER_NAME" "CARLFINDER" "SERVER_NAME"
	editVariable "$MYSQL_PASSWORD" "" "MYSQL_PASSWORD"
	editVariable "$CCP_SSO_CLIENT_ID" "" "CCP_SSO_CLIENT_ID"
	editVariable "$CCP_SSO_SECRET_KEY" "" "CCP_SSO_SECRET_KEY"
	editVariable "$CCP_ESI_SCOPES" "esi-location.read_online.v1,esi-location.read_location.v1,esi-location.read_ship_type.v1,esi-ui.write_waypoint.v1,esi-ui.open_window.v1,esi-universe.read_structures.v1,esi-corporations.read_corporation_membership.v1,esi-clones.read_clones.v1" "CCP_ESI_SCOPES"
	source $CWD\.env
}

function confirm(){
	cecho -c 'green' "$@";
	declare -A menu=( [1]="NO" [0]="YES")
	wizzard;
	if [ ${menu[$UI_WIDGET_RC]} == "NO" ]; then
		menu
	fi
}


function import_pochven(){
	confirm "Do you want to import the Pochven Patch to your database?";
	docker-compose start pfdb 

	curl "https://raw.githubusercontent.com/Tupsi/pathfinder/7dee405612681c6436f35ef63a78843e78c2f58d/export/sql/pochven-patch.sql" | docker-compose exec -T pfdb /bin/sh -c 'cat - > /patch.sql && mysql -u root --password="$MYSQL_ROOT_PASSWORD" --verbose --execute="USE eve_universe; \. patch.sql"'

	cecho -c 'green' "Patch got sucessfully imported"
	sleep 10
}

function import_universe(){
	confirm "Do you want to import the eve universe dump?"
	docker-compose start pfdb 
	zcat pathfinder/export/sql/eve_universe.sql.zip |  docker-compose exec -T pfdb /bin/sh -c 'mysql --user="root" --password="$MYSQL_ROOT_PASSWORD" --database="eve_universe"'
}

function reset_password(){
	cecho -c 'RED' "This will delete your database and create a new one with your changed password! Procced with caution"
	confirm "Do you want to change your MYSQL ROOT Password"
	docker-compose down -v
	read -p "Password: ";
	docker-compose stop pfdb	
	docker-compose run  -v  db_data:/var/lib/mysql pfdb /bin/sh -c '(echo "USE mysql;UPDATE user SET Password=PASSWORD(\"'${REPLY}'\") WHERE User=\"root\";FLUSH PRIVILEGES;USE mysql" > /init.sql  && mysqld_safe --init-file=/init.sql &) & sleep 25 && exit';
}
function setup(){
	confirm "Do you want to start building pathfinder so you can run it?"
	docker-compose build
	tput clear;

	confirm "Do you want to import the eve_universe database ?"; 
	import_universe


	confirm "Do you want to start Pathfinder?";
	docker-compose up -d;
}

function menu(){
	while [ 0 ]; do
		tput clear
		declare -A menu=( [0]="Quit" [3]="Import Universe" [4]="Import Pochven Patch" [5]="Reset MYSQL_ROOT_Password" [6]="Setup" )

		cecho -c 'green' "Pathfinder Docker manage tool: \n";
		wizzard

		tput clear
		if [ "${menu[$UI_WIDGET_RC]}" == "Quit" ]; then
			exit 0;
		elif [ "${menu[$UI_WIDGET_RC]}" == "Import Universe" ]; then
			import_universe
		elif [ "${menu[$UI_WIDGET_RC]}" == "Import Pochven Patch" ]; then
			import_pochven
		elif [ "${menu[$UI_WIDGET_RC]}" == "Setup" ]; then
			setup
		elif [ "${menu[$UI_WIDGET_RC]}" == "Reset MYSQL_ROOT_Password" ]; then
			reset_password
		fi
	done
}
menu
