#!/bin/sh

set -e
# set -x

old_tag=$(git describe --tags --abbrev=0 --match "Release_*")

top_level=$(git rev-parse --show-toplevel)

if [ -z "$top_level" ]
then
  echo "This is not a git repository"
  exit 1
fi

for path in $(ls $top_level/Packages/MIES/*Macro.ipf)
do
  file=$(basename $path)

  for revision in HEAD $old_tag
  do
    output=controls_${file}_${revision}
    echo $output
    git show $revision:Packages/MIES/$file | grep -i -P                                                                      \
       "\b(Button|Checkbox|PopupMenu|ValDisplay|SetVariable|Chart|Slider|Tab|GroupBox|Titlebox|ListBox|CustomControl)\b.*" | \
       cut -f 1 -d "," | cut -f 2 -d " " | sort | uniq > $output
  done

  diff --unified=0 controls_${file}_${old_tag} controls_${file}_HEAD > controls_${file}_diff || true

  echo ""
  echo "Changed controls for ${file}"
  echo ""
  cat controls_${file}_diff
done
