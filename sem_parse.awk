#!/usr/bin/awk -f

# Remome the round brackets 
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
/:servobj\s+\(servobj/ {
	# Beginning of the servobj block
	servobj=1
	bracket=1
}

# : (FW1_mgmt
/^\s*:\s+\(\S+$/ {
	# Beginning of the object definition
	if (!servobj) next
	svc=1	
	bracket++
	svcname=unwrapsvc($0)
}

# )
/^\s*\)\s*$/ {
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

/^\s*:type\s/ {
	if (!svc || proto_type) next
	type=tolower(unwrap($0))
	switch (type) {
		case "group": 
			group=1
			break
		case "other": 
			type="ip"
			break
		case /icmp|tcp|udp/:
			break
		default:
			type="ignore"
			break
	}
}


/^\s*:proto_type\s\(\s*$/ {
	if (svc) { 
		proto_type=1
		bracket++
	}
}

/^\s*:port\s\S/ {
	if (svc) port=unwrap($0)
}

/^\s*:protocol\s/ {
	if (svc) port=unwrap($0)
}

# :icmp_type (3)
/^\s*:icmp_type\s/ {
	if (svc) port=unwrap($0)
}

# :exp ("dport=520,rip_cmd=RIPCMD_RESPONSE")
/^\s*:exp\s\(\S+.*\)/ {
	if (svc) expr=unwrap($0)
}

# Group members
#  : sqlnet2-1521
/^\s*:\s[^(]\S+$/ {
	if (!group) next
	if (members) members=members "," $NF
	else members=$NF
}

# Something else withinga service definition with an open bracket
#/^\s*:\S+\s+\(\s*$/ {
#	if (svc && servobj) bracket++
#}
