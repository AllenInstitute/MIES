#!/bin/sh

# Helper script to delete all bamboo build folder which are older than two weeks

find ~/bamboo-agent-home/xml-data/build-dir -maxdepth 1 -type d -not -path *repositories-cache* -mtime +15 | xargs rm  -rf
