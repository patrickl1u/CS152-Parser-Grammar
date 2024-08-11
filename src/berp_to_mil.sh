#!/bin/bash

#   Converts .berpl to .mil and executes MIL program
#   https://www.cs.ucr.edu/~dtan004/proj3/mil.html
#   in hindsight this could have been put into Makefile

#   Running:
#   compile in conjunction with 'make' as follows (in src dir):
#   make && ./berp_to_mil.sh berpl_source_file mil_output_file

#   with 'test.txt' run as:
#   make && ./berp_to_mil.sh test.txt test.mil

if [ -z "$1" ]
  then
    echo "Missing .berpl input file"
    echo "Usage: ./berp_to_mil.sh berpl_source_file mil_output_file"
    exit;
fi

if [ -z "$2" ]
  then
    echo "Missing .mil output file"
    echo "Usage: ./berp_to_mil.sh berpl_source_file mil_output_file"
    exit;
fi

# run berp-l, remove empty lines, 
# reverse output, print to stdout and save to file specified

# https://unix.stackexchange.com/questions/528332/how-display-output-command-and-pipe-it-to-next-command
# https://www.baeldung.com/linux/remove-blank-lines-from-file
# tac not needed inside tee to reverse output anymore
./berp-l < $1 | grep -v '^[[:space:]]*$' | tee $2

# mil_run does not output any errors with incorrect code
# will still run code 
# will error if undeclared variable used
# does not error if same variable declared twice in a function
# does not accept empty lines
echo "running mil..."
./mil_run $2 && echo "exiting..."
