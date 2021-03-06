#!/usr/bin/python

# This program takes CheckPoint configuration made by the following command:
# clish -c "show configuration"
# and generates policy based routing (PBR) rules to except local networks and
# local routes from the PBR scope
#
# Lines like: 

# set interface bond1.2 ipv4-address 1.2.3.1 mask-length 29

# are converted to

# set pbr table bond1o2 static-route 1.2.3.0/29 nexthop gateway logical bond1.2 priority 10
# set pbr rule priority 10 match to 1.2.3.0/29
# set pbr rule priority 10 action table bond1o2

# Lines like

# set static-route 10.175.255.0/24 nexthop gateway address 163.157.255.129 on

# are converted to

# set pbr table 10o175o255o0m24 static-route 10.175.255.0/24 nexthop gateway address 163.157.255.129 priority 100
# set pbr rule priority 100 match to 10.175.255.0/24
# set pbr rule priority 100 action table 10o175o255o0m24

# If a list of IP-addresses and a table name are given in the form of:

#1.2.3.4
#2.3.4.0 /23
# 3.4.5.0 255.255.252.0
#6.5.4.3/ 255.255.255.0

# set pbr rule priority 1000 match from 1.2.3.4/32
# set pbr rule priority 1000 action table default


import string
import argparse
import re
import sys
import datetime

try:
	import netaddr
except ImportError:
	print >>sys.stderr, 'ERROR: netaddr module not found. Add it by either\n \"apt install python-netaddr\" \n or\n \"pip install netaddr\"'
	sys.exit(1)

# Make a valid table name from inteface names (bond1.2 -> bond1o2) or network IP's (10.175.255.0/24 -> 10o175o255o0m24)
def tname(name):
	return "t"+re.sub(r'/','m',re.sub(r'\.','o',name))

def print_pbr_iface(iface, ip, mask):
	global cur_ifprio, table_prio
	table = tname(iface)
	addr=netaddr.IPNetwork(str(ip)+"/"+str(mask))
	clish("set pbr table {0!s} static-route {1!s} nexthop gateway logical {2!s} priority {3}".format(table, str(addr.cidr), iface, table_prio))
	clish("set pbr rule priority {0} match to {1!s}".format(cur_ifprio,str(addr.cidr)))
	clish("set pbr rule priority {0} action table {1!s}".format(cur_ifprio, table))

	cur_ifprio += 1

def print_pbr_route(ip, gw):
	global cur_rtprio, table_prio
	table = tname(ip)
	clish("set pbr table {0!s} static-route {1!s} nexthop gateway address {2!s} priority {3}".format(table,ip,gw,table_prio))
	clish("set pbr rule priority {0} match to {1!s}".format(cur_rtprio,ip))
	clish("set pbr rule priority {0} action table {1!s}".format(cur_rtprio,table))
	cur_rtprio += 1	
	
def print_pbr_list(ip,table):
	global cur_listprio, direction
	clish("set pbr rule priority {0} match {1!s} {2!s}".format(cur_listprio,direction,str(ip)))
	clish("set pbr rule priority {0} action table {1!s}".format(cur_listprio,table))
	cur_listprio +=1

# Takes a string, extracts IP-address and returns a netaddr object
def parse_list(line):
# Replace all duplicate spaces and tabs with one space
	line=re.sub('\s+',' ', line)
	if len(line.split(' ')) > 2:
		print >>sys.stderr, 'ERROR: wrong file format. This line contains too many fields:'
		print >>sys.stderr, line
		sys.exit(1)
# Is it a cidr notation	
	if "/" in line:
# Remove spaces and return the network object
		return netaddr.IPNetwork(re.sub('\s','',line))
# Is there network mask in the 255.255. notation?
	elif " " in line:
		return netaddr.IPNetwork(re.sub(' ','/',line))
	else:
		return netaddr.IPNetwork(line)
			
# Create object names:
# h-001.020.003.004  -- for hosts
# n-001.020.003.000_24 -- for networks			
# net - netaddr.IPNetwork(ip)
def net2name(ip):
	net=str(ip.network)
	mask=str(ip.prefixlen)
	if ishost(ip): return 'h-'+ip2txt(net)
	else: return 'n-'+ip2txt(net)+'_'+mask

# ip - string IP-address -- 1.2.3.4
# returns - 001.002.003.004
def ip2txt(ip):
	return ".".join(map(octet2txt,ip.split('.')))

# octet - string of 0...255 (e.g. 12, 1, 123)
# returns 012, 001, 123
def octet2txt(octet):
	if len(octet) < 3:
		octet = "0" + octet if len(octet) == 2 else "00" + octet
	return octet

# Returns True if the netmask is 32, and False otherwise
# ip is a netaddr object
def ishost(ip):
	return True if ip.prefixlen == 32 else False

# Gets a (str) line and (if no args.nodbedit set to True) wraps it in 
# 'echo -e ' line '\nupdate_all\\n-q\\n" | dbedit -local'
def dbedit(line):
	if args.nodbedit: print line
	else: print 'echo -e \"' + line + '\\nupdate_all\\n-q\\n" | dbedit -local'

# Prints the line surrounded by hashes
def banner(line):
	repeat=90
	print repeat*'#'
	print "#",line
	print repeat*'#'

# Get a str(line), and wraps it in
# clish -c " ... " if noclish=False
def clish(line):
	if args.noclish: print line
	else: print 'clish -c \"' + line + " \""
	
# ip_list - list netaddr objects
# group - name of the CheckPoint firewall group to add the IP-addresses to
def print_dbedit_cmds(ip_list,group):
	for ip in ip_list:
		name=net2name(ip)
		if ishost(ip):
			dbedit("create host_plain {0!s}".format(name))
			dbedit("modify network_objects {0!s} ipaddr {1!s}".format(name,str(ip.network)))
		else:
			dbedit("create network %s" % name)
			dbedit("modify network_objects {0!s} ipaddr {1!s}\\nmodify network_objects {0!s} netmask {2!s}".format(name,str(ip.network),str(ip.netmask)))
		dbedit("addelement network_objects {0!s} \'\' network_objects:{1!s}".format(group,name)) 

	
parser = argparse.ArgumentParser()
parser.add_argument('conf', default="-", nargs='?', help="Filename with a list of IP addresses, CheckPoint gateway conf filename, produced by \nclish -c 'show configuration' \nor \"-\" to read from the console (default)")
parser.add_argument('--noclish', default=False, help="Do not add \"clish -c\" decorations", action="store_true")
parser.add_argument('--ifprio', default=10, type=int, help="The beginning priority of the PBR rules, related to the interfaces, default=10")
parser.add_argument('--rtprio', default=100, type=int, help="The beginning priority of the PBR rules, related to the local routes, default=100")
parser.add_argument('--ignore_if', default="", help="Comma separated list of interfaces to ignore, default=mgmt,sync,lo")
parser.add_argument('--ignore_ip', default="", help="Comma separated list of IP-addresses to ignore, default=none")
parser.add_argument('--list', default=False, help="The input is a list of IP-addresses, not a clish config", action="store_true")
dir = parser.add_mutually_exclusive_group()
dir.add_argument('--dst', default=False, help="The list contains the destination addresses", action="store_true")
dir.add_argument('--src', default=False, help="The list contains the source addresses", action="store_true")
parser.add_argument('--nodbedit', default=False, help="Do not add dbedit decorations", action="store_true")
parser.add_argument('--table', default="default", help="Table name, default = default")
parser.add_argument('--listprio', default=1000, type=int, help="The beginning priority of the PBR rules for the list of servers, default=1000")
parser.add_argument('--fw', default=False, help="Create firewall commands to add the IP-addresses to the config", action="store_true")
parser.add_argument('--group', default="g-pbr", help="Group name to add the IP-addresses to, default = g-pbr")

args = parser.parse_args()
# cur_ifprio - current PBR priority for interface rules
# cur_rtprio - current PBR priority for local route rules
# cur_rtprio - current PBR priority for the list of IP-addresses rules
# table_prio - table priority
# direction - "direction" for the list of IP-addresses: "to" or "from""
global cur_ifprio, cur_rtprio, cur_listprio, direction, table_prio
cur_ifprio = args.ifprio
cur_rtprio = args.rtprio
cur_listprio = args.listprio

# List of IP-addresses to add to the CheckPoint group
ip_list = []

ignore_if="mgmt|sync|lo"
if args.ignore_if:
# Added " " at the end of the interface names to distinguish between 1.2 and 1.21 	
	ignore_if=re.sub(r'\.','\.',re.sub(r',','[ ]|',args.ignore_if)) + "[ ]|" + ignore_if

# Do we need to ignore any IP-addresses besides the default route?
if args.ignore_ip:
	ignore_ip="default|"+re.sub(r'\.','\.',re.sub(r',','[ ]|',args.ignore_ip)) + "[ ]"
else:
	ignore_ip="default"

if args.list:
	if args.dst: 
		direction="to"
	elif args.src:
		direction="from"
	else:
		print >>sys.stderr, 'ERROR: the \"--list\" option requires either \"--src\" or \"--dst\" '
		sys.exit(1)
		
# set interface bond1.2 ipv4-address 1.2.3.1 mask-length 29
re_intf = re.compile(r'set\s+interface\s+(?P<ifname>\S+)\s+ipv4-address\s+(?P<ip>\S+)\s+mask-length\s+(?P<mask>\S+)', re.IGNORECASE)

# set static-route 10.175.255.0/24 nexthop gateway address 163.157.255.129 on
re_route = re.compile(r'set\s+static-route\s+(?P<ip>\S+)\s+nexthop\s+gateway\s+address\s+(?P<gw>\S+)\s+on', re.IGNORECASE)

# Names of interfaces to ignore
re_ignore_if = re.compile(ignore_if, re.IGNORECASE)

#IP addresses to ignore
re_ignore_ip = re.compile(ignore_ip)

if "-" == args.conf:
	f=sys.stdin		
else: 
	try:
		 f=open (args.conf,"r")
	except IOError:
		print >>sys.stderr, 'ERROR: Can\'t open file', args.conf
		sys.exit(1)

banner('Run these commands on the firewall(s)')
now=datetime.datetime.now()
print 'clish -c "show configuration" > ~/firewall_clish_before.%s.conf' % now.strftime("%Y%m%d_%H%M")
clish("lock database override")

# If a list of IP-addresses is provided:
if args.list:
	for line in f:
		line = line.strip()	
		ip = parse_list(line)
		print_pbr_list(ip,args.table)
		ip_list.append(ip)
# If a clish config provided:
else:
	for line in f:
		line = line.strip()
# Is it interface config line?
		if re_intf.search(line):
			res=re_intf.search(line)
			ifname=res.group('ifname')
			ip=res.group('ip')
			table_prio = 2
# Checking if the line should be ignored		
# Added " " at the end of the interface names to distinguish between 1.2 and 1.21 			
			if not re_ignore_if.search(ifname + " ") and not re_ignore_ip.search(ip + " "):
				print_pbr_iface(ifname, ip, res.group('mask'))
# If it's a static route line?
		elif re_route.search(line):
			ip=re_route.search(line).group('ip')
			gw=re_route.search(line).group('gw')
			table_prio = 3
# Checking if the line should be ignored		
			if not re_ignore_ip.search(ip + " ") and not re_ignore_ip.search(gw + " "):
				print_pbr_route(ip, gw)
print 'clish -c "show configuration" > ~/firewall_clish_after.%s.conf' % now.strftime("%Y%m%d_%H%M")				
banner("After tested OK, save the config with: clish, save config")

# If needed creating CheckPoint dbedit commands to add IP-addresses to the specified group
if args.fw:
	banner("Make a DB backup, then run these commands on the management station")
	print_dbedit_cmds(ip_list,args.group)
	banner("Install the new policy")
	
