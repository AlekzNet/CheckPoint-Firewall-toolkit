## cpconf2pbr.py

cpconf2pbr.py creates PBR rules, based on:
* CheckPoint GAIA clish configuration
* List of IP addresses ("from" only at this time)

### Usage:

```txt
usage: cpconf2pbr.py [-h] [--noclish] [--ifprio IFPRIO] [--rtprio RTPRIO]
                     [--ignore_if IGNORE_IF] [--ignore_ip IGNORE_IP] [--list]
                     [--dst | --src] [--table TABLE] [--listprio LISTPRIO]
                     [conf]

positional arguments:
  conf                  Filename with a list of IP addresses, CheckPoint
                        gateway conf filename, produced by clish -c 'show
                        configuration' or "-" to read from the console
                        (default)

optional arguments:
  -h, --help            show this help message and exit
  --noclish             Do not add "clish -c" construction
  --ifprio IFPRIO       The beginning priority of the PBR rules, related to
                        the interfaces, default=10
  --rtprio RTPRIO       The beginning priority of the PBR rules, related to
                        the local routes, default=100
  --ignore_if IGNORE_IF
                        Comma separated list of interfaces to ignore,
                        default=mgmt,sync,lo
  --ignore_ip IGNORE_IP
                        Comma separated list of IP-addresses to ignore,
                        default=none
  --list                The input is a list of IP-addresses, not a clish
                        config
  --dst                 The list contains the destination addresses
  --src                 The list contains the source addresses
  --table TABLE         Table name, default = default
  --listprio LISTPRIO   The beginning priority of the PBR rules for the list
                        of servers, default=1000

```

If tested OK, save the configuration with:

```txt
clish -c "save config"
```

### "Exception" PBR rules based on the clish config

This mode is used to create PBR rule to except the local traffic from the PBR. All traffic destined to the directly connected networks or non-default routes will be exempted from the PBR rules with the lower priority.

The source file should be made by the following command:

```txt
clish -c "show configuration"
```

#### Examples

Config lines:

```txt
set interface bond1.2 ipv4-address 1.2.3.1 mask-length 29
set static-route 10.175.255.0/24 nexthop gateway address 163.157.255.129 on
```
Command:

```txt
cat config.txt | cpconf2pbr.py
```

Result:

```txt
clish -c "set pbr table bond1o2 static-route 1.2.3.1/29 nexthop gateway logical bond1.2 priority 10 "
clish -c "set pbr rule priority 10 match to 1.2.3.0/29 "
clish -c "set pbr rule priority 10 action table bond1o2 "
clish -c "set pbr table 10o175o255o0m24 static-route 10.175.255.0/24 nexthop gateway address 163.157.255.129 priority 100 "
clish -c "set pbr rule priority 100 match to 10.175.255.0/24 "
clish -c "set pbr rule priority 100 action table 10o175o255o0m24 "
```


### PBR rules based on an IP-list

Create the real PBR rules for a list of IP-addresses

#### Examples

List of IP-addresses:

```txt
cat testpbrlist.txt  
1.2.3.4
2.3.4.0 /23
 3.4.5.0 255.255.252.0
6.5.4.3/ 255.255.255.0
```

Command:

```txt
cpconf2pbr.py --list --src  --table deftable testpbrlist.txt
```

Result:

```txt
clish -c "set pbr rule priority 1000 match from 1.2.3.4/32 "
clish -c "set pbr rule priority 1000 action table deftable "
clish -c "set pbr rule priority 1001 match from 2.3.4.0/23 "
clish -c "set pbr rule priority 1001 action table deftable "
clish -c "set pbr rule priority 1002 match from 3.4.5.0/22 "
clish -c "set pbr rule priority 1002 action table deftable "
clish -c "set pbr rule priority 1003 match from 6.5.4.3/24 "
clish -c "set pbr rule priority 1003 action table deftable "
```
