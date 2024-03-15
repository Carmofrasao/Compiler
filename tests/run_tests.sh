#!/bin/bash

# Run 'make clean && make' to compile your code and clean build artifacts
# makefile already does this, to run script my hand, uncomment the following line
# make clean --no-print-directory && make --no-print-directory

# Define the input and expected output folders
input_folder="tests/input"
output_folder="tests/expected_output"

output="output/output.mepa"

# Define ANSI color escape codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Iterate through all pairs of fileX.pas and outputX.txt files
for input_file in $input_folder/*.pas; do
    # ignore if starts with underline "_"
    if [[ "$(basename "$input_file")" =~ ^_ ]]; then
        continue;
    fi
    
    # Extract the corresponding output file name
    output_file="$output_folder/$(basename "$input_file" .pas).mepa"
    
    # Run the compiler and redirect output to a temporary file
    ./compilador < "$input_file" > /dev/null 2>&1
    
    # Use 'diff' to compare the output with the expected output, ignoring white spaces and new lines
    if diff -wB $output "$output_file" ; then
        echo -e "${GREEN}passed $(basename "$input_file")${NC}"
    else
        echo -e "${RED}failed $(basename "$input_file")${NC}"
    fi
    
    # Clean up temporary files
    # rm temp_output.txt
done
