## cpconf2pbr.py

cpconf2pbr.py creates PBR rules, based on:
* CheckPoint GAIA clish configuration
* List of IP addresses ("from" only at this time)

### Usage:

```txt
usage: cpconf2pbr.py [-h] [--noclish] [--ifprio IFPRIO] [--rtprio RTPRIO]
                     [--ignore_if IGNORE_IF] [--ignore_ip IGNORE_IP] [--list]
                     [--table TABLE] [--listprio LISTPRIO]
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
  --table TABLE         Table name, default = default
  --listprio LISTPRIO   The beginning priority of the PBR rules for the list
                        of servers, default=1000
```

### "Exception" PBR rules based on the clish config

#### Examples

### PBR rules based on an IP-list

#### Examples

