#!/bin/bash

set -e

for i in $(find -iname "JU_*.xml")
do
  xmllint --noout $i
done
