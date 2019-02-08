#!/bin/bash

cat $FWCONF/conf/sem_objects.C | sed -e 's/\s\s*/ /g'   | awk '

# Remove the round brackets 
function unwrap(word) {
	return gensub(/.*\((.*)\).*/,"\\1","g",word)
}

# Remove the left bracket
function unwrapsvc(line) {
	return gensub(/.*\((.*)$/,"\\1","g",line)
}

BEGIN { 
	servobj=0
	bracket=0
	svc=0
	type=""
	port=""
	group=0
	members=""
	proto_type=0
	expr=""
}

# :servobj (servobj
/:servobj[ ]+\(servobj/ {
	# Beginning of the servobj block
	servobj=1
	bracket=1
}

# : (FW1_mgmt
/^[ ]*:[ ]+\([^ ]+$/ {
	# Beginning of the object definition
	if (!servobj) next
	svc=1	
	bracket++
	svcname=unwrapsvc($0)
}

# )
/^[ ]*\)[ ]*$/ {
	# End of the object definition
	if (!servobj) next
	bracket--
	if (bracket <= 0) {
		servobj=0
		next
	}
	if (proto_type) {
		proto_type=0
		next
	}
	# End of the servobj section?

	if (group) {
		print svcname " " members
	}
	else if (type != "ignore") {
		print svcname " " type ":" port " " expr
	}
	expr=""
	svc=0
	type=""
	port=""
	group=0
	members=""
}

/^[ ]*:type[ ]/ {
	if (!svc || proto_type) next
	type=tolower(unwrap($0))
	if (type == "group") group=1
	else if (type == "other") type ="ip"
	else if (type == "icmp" || type == "tcp" || type == "udp") next
	else type="ignore"
}


/^[ ]*:proto_type[ ]\([ ]*$/ {
	if (svc) { 
		proto_type=1
		bracket++
	}
}

/^[ ]*:port[ ][^ ]/ {
	if (svc) port=unwrap($0)
}

/^[ ]*:protocol[ ]/ {
	if (svc) port=unwrap($0)
}

# :icmp_type (3)
/^[ ]*:icmp_type[ ]/ {
	if (svc) port=unwrap($0)
}

# :exp ("dport=520,rip_cmd=RIPCMD_RESPONSE")
/^[ ]*:exp[ ]\([^ ]+.*\)/ {
	if (svc) expr=unwrap($0)
}

# Group members
#  : sqlnet2-1521
/^[ ]*:[ ][^(][^ ]+$/ {
	if (!group) next
	if (members) members=members "," $NF
	else members=$NF
}

'
