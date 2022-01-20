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
    if (';' in line) or (line == "\t.data\n") or (line == "\n") or (line == " \n") or (line == "\t\n"):  # Skip lines
        pass
    else:
        line = line.strip("\n")
        data = line.split("\t")
        while '' in data:                   # Remove blank entries
            data.remove('')

        values = data[2].split(" ")
        # print(f"{data} -- {values}")
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
labels = {}
while line != '':
    if (';' in line) or (line == "\t.text\n") or (line == "\n") or (line == " \n") or (line == "\t\n") \
            or (line == "\t\t\n") or (line == "\t"):  # Skip lines
        pass
    else:
        line = line.strip("\n")
        if line[0] == "\t":
            items = line.split("\t")
            while '' in items:      # Remove blank entries
                items.remove('')

            # This is where each OPCODE is going to be evaluated
            word = ""
            if items[0] == "NOP":
                word = "0" * 32
            # TODO: OPCODEs below HERE still need to be evaluated
            elif items[0] == "LW":
                word = f"{1:>06X}"
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "SW":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "ADD":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "ADDI":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "ADDU":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "ADDUI":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "SUB":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "SUBI":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "SUBU":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "SUBUI":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "AND":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "ANDI":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "OR":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "ORI":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "XOR":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "XORI":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "SLL":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "SLLI":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "SRL":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "SRLI":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "SRA":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "SRAI":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "SLT":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "SLTI":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "SLTU":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "SLTUI":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "SGT":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "SGTI":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "SGTU":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "SGTUI":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "SLE":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "SLEI":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "SLEU":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "SLEUI":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "SGE":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "SGEI":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "SGEU":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "SGEUI":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "SEQ":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "SEQI":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "SNE":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "SNEI":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "BEQZ":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "BNEZ":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "J":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "JR":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "JAL":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            elif items[0] == "JALR":
                print(f"\033[31m Need to write code for {items[0]} \033[0m")
            else:
                print(f"\033[31m Error: OPCODE {items[0]} unknown \033[0m")

            print(f"{i:>03X} {items}")
            i += 1
        else:
            labels[line] = i + 1            # This will set up a place we can reference absolute addresses

    line = source_file.readline()

code_file.write("\nEND;\n")
code_file.close()
source_file.close()
