#!/bin/bash
for i in $(hammer content-view list | tail -n +4 | sed '$d' | awk '{print $1}') ; do hammer content-view info --id $i --fields "Id","Name","Content host count" | tr '\n' ',' ; echo -e "" ; done
