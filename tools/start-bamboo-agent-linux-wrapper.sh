#!/bin/sh

set -e

if [ "$(whoami)" = "root" ]
then
	echo "Can not be run as root" > /dev/stderr
	exit 1
fi

tmux new-session -d -s bamboo-agent
tmux send-keys -t bamboo-agent /home/thomasb/start_bamboo_agent.sh ENTER
