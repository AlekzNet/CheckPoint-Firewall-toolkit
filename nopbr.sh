#!/bin/bash
# Remove all PBR tables and rules from CheckPoint GAIA config

for i in `clish -c "show configuration" | fgrep "set pbr table" | awk '{print $4}'`
do
	clish -c "set pbr table $i off"
done

for i in `clish -c "show configuration" | fgrep "set pbr rule priority" | awk '{print $5}' | sort -u`
do
	clish -c "set pbr rule priority $i off"
done
