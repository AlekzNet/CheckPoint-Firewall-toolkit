#!/usr/bin/python
####################################################################
# Name: Cparser.py
# Function: Accept any CheckPoint .C file and convert into Python list format
# Parameters:
#         Arg1: Input file - Any .C file like cp-admin.C or objects.C
#         Arg2: Output file
# Comment: I probably could of done this in 1 line in Perl, but this is
#          python program #1 for me
#########################################################################

import re
import pprint
import sys

#
# Globals
#
idx=0 # line index
idy=0 # line list index
lines=[]

re_word=re.compile(r'(?P<word>[^\s\)\(]+)')
re_quote=re.compile(r'(?P<quote>".*?")')
re_spaces=re.compile(r'\s+') 	# lots of spaces/tabs
re_indent=re.compile(r'^\s+|:')	# spaces at the beginning
re_colon=re.compile(r'^\s*:') 		# colon
re_single=re.compile(r'^\s*[)(:]') # if the line does not begin with ),( or : it's a part of a multiline statement

#
# Recursively process one character at a time
#
def next_token():
    global idx, idy, lines
    parendata = [] # Parendata keep track of the Python list we are building
    while (idy < len(lines)):
		# go through each character 1 at a time    
		while (idx < len(lines[idy])):
			line = lines[idy]
#			print "INPUT: " + str(idx) + ":" + line[idx] + " line# " + str(idy)
			# Each '(' and ')' we will recursively decend and return
			if (line[idx] == '('):
			   #print (line[idx] + "(Open")
			   idx += 1
			   returnlist = next_token()
			   parendata.append([item for item in returnlist])
			elif (line[idx] == ')'):
			   idx += 1
			   return parendata
			# process anything within quotation marks
			elif (line[idx] == '"'):
#			   print line, line[idx] + " Quote " + str(idx) + " Line #" + str(idy+1)
			   _r = re_quote.search(line[idx:])
			   parendata.append(_r.group('quote'))
			   idx=idx + _r.end()
			# ignore space characters
			elif (line[idx].isspace()):
				idx += 1
			# process regular words
			# type format is...
			#(
			#: (MMM_Global_Read-Only
			#	    :AdminInfo (
			#	        :chkpf_uid ("155A28A8-D9BC-4EEB-A78C-334326D4B67F}")
			# So you will be picking up the MMM_Global_Read-Only, AdminInfo, chkpf_uid
			else:
				_r = re_word.search(line[idx:])
				parendata.extend([_r.group('word')])
				idx += _r.end()
		idx = 0
		idy += 1
		
    return parendata

def cleanup(line):
	line=line.strip()
	line=re_spaces.sub(" ",line)
	line=re_indent.sub("",line)	
	line=re_colon.sub("",line)	
	return line

###
### Parse the file and then pretty print output
###

def parse(fileout):
	parendata=next_token()
	pprint.pprint ( parendata,width=100,indent=1,stream=fileout)
	return parendata

########################  MAIN ##################################

##
##   open the input and output files and parse them
##


fileout=sys.stdout
from sys import argv, stdin
if len(argv) >= 2:
	# Open input file
	with open(argv[1],'r') as f:
		for line in open(argv[1]):
#			pprint.pprint (line)
			if not re_single.search(line) and not len(lines) <= 1:
#				print "=> not single"
#				pprint.pprint(line)
				lines[-1]=lines[-1]+" "+cleanup(line)
#				pprint.pprint(lines[-1])
			else:
				lines.append(cleanup(line))
				
		# open output file if present otherwise stdout
		if len(argv) == 3:
			fileout= open(argv[2],'w')
		# parse the file
		parse(fileout)

else: print >> sys.stderr, 'Args: [<.C file in>  <outputfile> ]'
