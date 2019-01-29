# CheckPoint_toolkit
Various tools to work with CheckPoint firewall

## Files

* [cpconf2pbr.py](https://github.com/AlekzNet/CheckPoint-toolkit/blob/master/doc/cpconf2pbr.md) - create CheckPoint GAIA PBR rules and local exceptions
* nopbr.sh - PBR tables and rules removal for CheckPoint GAIA 
* fw_stat_ip_list.sh - shows statistics of the allowed traffic related to specified IP-addresses
* fw_stat_ip_list_10min.sh - same as above, but for every 10min
* cparse.sh - parses objects.C and shows firewall objects in the form of `name (IP-address) (IP-address) ...`
* logex.sh - convert CheckPoint firewall logs to gzipped text

For both fw_stat_ip_list.sh and fw_stat_ip_list_10min.sh, the CheckPointlogs should be converted to TXT (e.g. using logex.sh) using the following format:

```txt
num;date;time;src;dst;proto;service;action
```
See the explanation here: https://www.alekz.net/archives/1480

### logex.sh

Create `/etc/fw/conf/logexport.ini`
```txt
[Fields_Info]
included_fields=date,time,src,dst,proto,service,action,xlatesrc,xlatedst,peer gateway,<REST_OF_FIELDS>
```

Check/change/create the `OUTDIR` (see logex.sh)

Run logex.sh using the first part of the CheckPoint log names (e.g. `2019-01`, `2019-01-01` or  `2019-01-2[1-9]`, etc) as an argument:

```txt
./logex.sh  2018-12 2019-01-19 2019-01-2[1-9] 
```
