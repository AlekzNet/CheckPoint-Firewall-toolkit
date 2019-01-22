# CheckPoint_toolkit
Various tools to work with CheckPoint firewall

## Files

* [cpconf2pbr.py](https://github.com/AlekzNet/CheckPoint-toolkit/blob/master/doc/cpconf2pbr.md) - create CheckPoint GAIA PBR rules and local exceptions
* nopbr.sh - PBR tables and rules removal for CheckPoint GAIA 
* fw_stat_ip_list.sh - shows statistics of the allowed traffic related to specified IP-addresses
* fw_stat_ip_list_10min.sh - same as above, but for every 10min
* cparse.sh - shows firewall objects in the form of `"name" (IP-address) (IP-address) ...`

For both fw_stat_ip_list.sh and fw_stat_ip_list_10min.sh, the CheckPointlogs should be converted to TXT using the following format:

```txt
num;date;time;src;dst;proto;service;action
```
See the explanation here: https://www.alekz.net/archives/1480
