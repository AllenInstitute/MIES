#!/bin/bash

set -e

for i in $(ls *.xml)
do
  xmllint --noout $i
done
