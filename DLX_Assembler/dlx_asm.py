#!/usr/bin/python

import sys

if len(sys.argv) < 3:
    print("Not enough arguments, needs 3")
    print("python dlx_asm.py <source_file>.dlx <data_file>.mif <code_file>.mif")

source_file_name = sys.argv[1]
data_file_name = sys.argv[2]
code_file_name = sys.argv[3]

source_file = open(source_file_name, 'r')
data_file = open(data_file_name, 'w')
code_file = open(code_file_name, 'w')

if source_file.closed:
    print(f"File: {source_file_name} could not be opened")

if data_file.closed:
    print(f"File: {data_file_name} could not be opened")

if code_file.closed:
    print(f"File: {code_file_name} could not be opened")

# Parse the .data section
#       This section shouldn't change from file to file
data_file.write("DEPTH = 1024;\n")
data_file.write("WIDTH = 32;\n")
data_file.write("ADDRESS_RADIX = HEX;\n")
data_file.write("DATA_RADIX = HEX;\n")
data_file.write("CONTENT\n")
data_file.write("BEGIN\n")
data_file.write("\n")

line = source_file.readline()
i = 0
while line != "\t.text\n":
    if (line[0] == ';') or (line == "\t.data\n") or (line == "\n") or (line == " \n") or (line == "\t\n"):  # Skip lines
        pass
    else:
        line = line.strip("\n")
        data = line.split("\t")
        while '' in data:                   # Remove blank entries
            data.remove('')

        values = data[2].split(" ")
        print(f"{data} -- {values}")
        if len(values) != int(data[1]):
            print(f"Error: {data[1]} != {len(values)}")
            sys.exit(1)
        for index in range(len(values)):
            data_file.write(f"{i:>03X} : {int(values[index]):>08X}; --{data[0]}[{index}]\n")
            i += 1

    line = source_file.readline()

data_file.write("\nEND;\n")
data_file.close()

# Parse the .text section

code_file.write("DEPTH = 1024;\n")
code_file.write("WIDTH = 32;\n")
code_file.write("ADDRESS_RADIX = HEX;\n")
code_file.write("DATA_RADIX = HEX;\n")
code_file.write("CONTENT\n")
code_file.write("BEGIN\n")
code_file.write("\n")

i = 0
while source_file:
    print(line)
    line = source_file.realine()

code_file.write("\nEND;\n")
code_file.close()
source_file.close()
