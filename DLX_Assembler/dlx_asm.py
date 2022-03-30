#!/usr/bin/python

import sys


def run():
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
    data_file.write("DEPTH = 1024; \n")
    data_file.write("WIDTH = 32; \n")
    data_file.write("ADDRESS_RADIX = HEX; \n")
    data_file.write("DATA_RADIX = HEX; \n")
    data_file.write("CONTENT \n")
    data_file.write("BEGIN \n")
    data_file.write(" \n")

    line = source_file.readline()
    i = 0
    variable = {}
    while line.strip("\t") != ".text\n" and (line.strip("\t").strip(" ") != ".const\n"):
        if (';' in line) or (line.strip("\t").strip(" ") == ".data\n")\
                or (line.strip("\t").strip(" ") == "\n"):  # Skip lines
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
            variable[data[0]] = i   # Save the addresses for reference in the code
            for index in range(len(values)):
                data_file.write(f"{i:>03X} : {int(values[index]):>08X};  --{data[0]}[{index}] \n")
                i += 1

        line = source_file.readline()

    while line.strip("\t") != ".text\n":
        if (';' in line) or (line.strip("\t").strip(" ") == ".const\n")\
                or (line.strip("\t").strip(" ") == ".data\n") or (line.strip("\t").strip(" ") == "\n"):  # Skip lines
            pass
        else:
            line = line.strip("\n")
            data = line.split("\t")
            while '' in data:                   # Remove blank entries
                data.remove('')

            values = data[2].replace('"', "")
            # print(f"{data} -- {values}")
            if len(values) != int(data[1]):
                print(f"Error: {data[1]} != {len(values)}")
                sys.exit(1)
            variable[data[0]] = i   # Save the addresses for reference in the code
            data_file.write(f"{i:>03X} : {int(data[1]):>08X};  --{data[0]} len: {data[1]}\n")
            i += 1
            for index in range(len(values)):
                data_file.write(f"{i:>03X} : {ord(values[index]):>08X};  --{data[0]}[{index}] {values[index]}\n")
                i += 1

        line = source_file.readline()

    data_file.write(" \nEND; ")
    data_file.close()

    # Parse the .text section

    code_file.write("DEPTH = 1024; \n")
    code_file.write("WIDTH = 32; \n")
    code_file.write("ADDRESS_RADIX = HEX; \n")
    code_file.write("DATA_RADIX = HEX; \n")
    code_file.write("CONTENT \n")
    code_file.write("BEGIN \n")
    code_file.write(" \n")

    i = 0
    labels = {}
    current_pos = source_file.tell()

    # Read all the labels
    while line != '':
        if (';' in line) or (line.strip("\t") == ".text\n") or (line.strip("\t") == "\n") or (line.strip(" ") == "\n") \
                or (line == "\t"):  # Skip lines
            pass
        else:
            line = line.strip("\n")
            items = line.split("\t")
            while '' in items:  # Remove blank entries
                items.remove('')

            if (len(items) == 1) and (items[0].islower()):
                labels[items[0]] = i
            else:
                i += 1

        line = source_file.readline()

    i = 0
    source_file.seek(current_pos)       # Reset to the position saved earlier
    line = source_file.readline()
    while line != '':
        if (';' in line) or (line == "\t.text\n") or (line == "\n") or (line == " \n") or (line == "\t\n") \
                or (line == "\t\t\n") or (line == "\t"):  # Skip lines
            pass
        else:
            line = line.strip("\n")
            items = line.split("\t")
            while '' in items:      # Remove blank entries
                items.remove('')

            if (len(items) == 1) and (items[0].islower()):                      # It's a label
                line = source_file.readline()
                continue

            # This is where each OPCODE is going to be evaluated
            word = "000000"
            if items[0] == "NOP":
                word = "0" * 32
                code_file.write(f"{i:>03X} : {int(word, 2):>08X};  --NOP \n")
                i += 1
                line = source_file.readline()
                continue
            elif items[0] == "LW":
                word = "000001"  # opcode
                params = items[1].split(", ")
                r_data = params[0].replace('R', '')
                r_data = bin(int(r_data))[2:]       # Convert string to a binary integer string without the '0b' at front
                word += f"{r_data:>05}"
                r_offset = params[1].split("(")[1][1:-1]        # This extracts y from the format x(Ry)
                r_offset = bin(int(r_offset))[2:]
                word += f"{r_offset:>05}"
                base = variable.get(params[1].split("(")[0])
                base = bin(int(base))[2:]
                word += f"{base:>016}"
            elif items[0] == "SW":
                word = "000010"  # opcode
                params = items[1].split(", ")
                r_data = params[1].replace('R', '')
                r_data = bin(int(r_data))[2:]       # Convert string to a binary integer string without the '0b' at front
                word += f"{r_data:>05}"
                r_offset = params[0].split("(")[1][1:-1]        # This extracts y from the format x(Ry)
                r_offset = bin(int(r_offset))[2:]
                word += f"{r_offset:>05}"
                base = variable.get(params[0].split("(")[0])
                base = bin(int(base))[2:]
                word += f"{base:>016}"
            elif items[0] == "ADD":
                word = "000011"  # opcode
                word += parse_registers(items[1])
            elif items[0] == "ADDI":
                word = "000100" # opcode
                word += parse_immediate(items[1])
            elif items[0] == "ADDU":
                word = "000101"  # opcode
                word += parse_registers(items[1])
            elif items[0] == "ADDUI":
                word = "000110"  # opcode
                word += parse_immediate(items[1])
            elif items[0] == "SUB":
                word = "000111"  # opcode
                word += parse_registers(items[1])
            elif items[0] == "SUBI":
                word = "001000"  # opcode
                word += parse_immediate(items[1])
            elif items[0] == "SUBU":
                word = "001001"  # opcode
                word += parse_registers(items[1])
            elif items[0] == "SUBUI":
                word = "001010"  # opcode
                word += parse_immediate(items[1])
            elif items[0] == "AND":
                word = "001011"  # opcode
                word += parse_registers(items[1])
            elif items[0] == "ANDI":
                word = "001100"  # opcode
                word += parse_immediate(items[1])
            elif items[0] == "OR":
                word = "001101"  # opcode
                word += parse_registers(items[1])
            elif items[0] == "ORI":
                word = "001110"  # opcode
                word += parse_immediate(items[1])
            elif items[0] == "XOR":
                word = "001111"  # opcode
                word += parse_registers(items[1])
            elif items[0] == "XORI":
                word = "010000"  # opcode
                word += parse_immediate(items[1])
            elif items[0] == "SLL":
                word = "010001"  # opcode
                word += parse_registers(items[1])
            elif items[0] == "SLLI":
                word = "010010"  # opcode
                word += parse_immediate(items[1])
            elif items[0] == "SRL":
                word = "010011"  # opcode
                word += parse_registers(items[1])
            elif items[0] == "SRLI":
                word = "010100"  # opcode
                word += parse_immediate(items[1])
            elif items[0] == "SRA":
                word = "010101"  # opcode
                word += parse_registers(items[1])
            elif items[0] == "SRAI":
                word = "010110"  # opcode
                word += parse_immediate(items[1])
            elif items[0] == "SLT":
                word = "010111"  # opcode
                word += parse_registers(items[1])
            elif items[0] == "SLTI":
                word = "011000"  # opcode
                word += parse_immediate(items[1])
            elif items[0] == "SLTU":
                word = "011001"  # opcode
                word += parse_registers(items[1])
            elif items[0] == "SLTUI":
                word = "011010"  # opcode
                word += parse_immediate(items[1])
            elif items[0] == "SGT":
                word = "011011"  # opcode
                word += parse_registers(items[1])
            elif items[0] == "SGTI":
                word = "011100"  # opcode
                word += parse_immediate(items[1])
            elif items[0] == "SGTU":
                word = "011101"  # opcode
                word += parse_registers(items[1])
            elif items[0] == "SGTUI":
                word = "011110"  # opcode
                word += parse_immediate(items[1])
            elif items[0] == "SLE":
                word = "011111"  # opcode
                word += parse_registers(items[1])
            elif items[0] == "SLEI":
                word = "100000"  # opcode
                word += parse_immediate(items[1])
            elif items[0] == "SLEU":
                word = "100001"  # opcode
                word += parse_registers(items[1])
            elif items[0] == "SLEUI":
                word = "100010"  # opcode
                word += parse_immediate(items[1])
            elif items[0] == "SGE":
                word = "100011"  # opcode
                word += parse_registers(items[1])
            elif items[0] == "SGEI":
                word = "100100"  # opcode
                word += parse_immediate(items[1])
            elif items[0] == "SGEU":
                word = "100101"  # opcode
                word += parse_registers(items[1])
            elif items[0] == "SGEUI":
                word = "100110"  # opcode
                word += parse_immediate(items[1])
            elif items[0] == "SEQ":
                word = "100111"  # opcode
                word += parse_registers(items[1])
            elif items[0] == "SEQI":
                word = "101000"  # opcode
                word += parse_immediate(items[1])
            elif items[0] == "SNE":
                word = "101001"  # opcode
                word += parse_registers(items[1])
            elif items[0] == "SNEI":
                word = "101010"  # opcode
                word += parse_immediate(items[1])
            elif items[0] == "BEQZ":
                word = "101011"
                params = items[1].split(", ")
                rs1 = params[0].replace('R', '')
                rs1 = bin(int(rs1))[2:]
                word += f"{rs1:>05}"
                adr = labels.get(params[1])
                adr = bin(int(adr))[2:]
                word += f"{adr:>021}"
            elif items[0] == "BNEZ":
                word = "101100"
                params = items[1].split(", ")
                rs1 = params[0].replace('R', '')
                rs1 = bin(int(rs1))[2:]
                word += f"{rs1:>05}"
                adr = labels.get(params[1])
                adr = bin(int(adr))[2:]
                word += f"{adr:>021}"
            elif items[0] == "J":
                word = "101101"
                adr = labels.get(items[1])
                adr = bin(int(adr))[2:]
                word += f"{adr:>026}"
            elif items[0] == "JR":
                word = "101110"
                rs1 = items[1].replace('R', '')
                rs1 = bin(int(rs1))[2:]
                word += f"{rs1:>010}"
                word += "0" * 16
            elif items[0] == "JAL":
                word = "101111"
                adr = labels.get(items[1])
                adr = bin(int(adr))[2:]
                word += f"{adr:>026}"
            elif items[0] == "JALR":
                word = "110000"
                rs1 = items[1].replace('R', '')
                rs1 = bin(int(rs1))[2:]
                word += f"{rs1:>010}"
                word += "0" * 16
            elif items[0] == "PCH":
                word = "110001"
                rs1 = items[1].replace('R', '')
                rs1 = bin(int(rs1))[2:]
                word += f"{rs1:>010}"
                word += "0" * 16
            elif items[0] == "PD":
                word = "110010"
                rs1 = items[1].replace('R', '')
                rs1 = bin(int(rs1))[2:]
                word += f"{rs1:>010}"
                word += "0" * 16
            elif items[0] == "PDU":
                word = "110011"
                rs1 = items[1].replace('R', '')
                rs1 = bin(int(rs1))[2:]
                word += f"{rs1:>010}"
                word += "0" * 16
            elif items[0] == "GD":
                word = "110100"
                rs1 = items[1].replace('R', '')
                rs1 = bin(int(rs1))[2:]
                word += f"{rs1:>010}"
                word += "0" * 16
            elif items[0] == "GDU":
                word = "110101"
                rs1 = items[1].replace('R', '')
                rs1 = bin(int(rs1))[2:]
                word += f"{rs1:>010}"
                word += "0" * 16
            elif items[0] == "TR":
                word = "110110"
                word += "0" * 26
                code_file.write(f"{i:>03X} : {int(word, 2):>08X};  --TR \n")
                i += 1
                line = source_file.readline()
                continue
            elif items[0] == "TGO":
                word = "110111"
                word += "0" * 26
                code_file.write(f"{i:>03X} : {int(word, 2):>08X};  --TGO \n")
                i += 1
                line = source_file.readline()
                continue
            elif items[0] == "TSP":
                word = "111000"
                word += "0" * 26
                code_file.write(f"{i:>03X} : {int(word, 2):>08X};  --TSP \n")
                i += 1
                line = source_file.readline()
                continue
            else:
                print(f"\033[31m Error: OPCODE '{items[0]}' unknown \033[0m")

            for label in labels:                # Replace labels with their absolute addresses
                if label in items[1].split(", "):
                    items[1] = items[1].replace(f"{label}", f"{labels[label]:>03X}")
            code_file.write(f"{i:>03X} : {int(word,2):>08X};  --{items[0]:<5} {items[1]} \n")
            i += 1
        line = source_file.readline()

    code_file.write(" \nEND; ")
    code_file.close()
    source_file.close()


def parse_registers(regs):
    params = regs.split(", ")
    rd = params[0].replace('R', '')
    rd = bin(int(rd))[2:]
    to_return = f"{rd:>05}"
    rs1 = params[1].replace('R', '')
    rs1 = bin(int(rs1))[2:]
    to_return += f"{rs1:>05}"
    rs2 = params[2].replace('R','')
    rs2 = bin(int(rs2))[2:]
    to_return += f"{rs2:>05}"
    to_return += "0" * 11
    return to_return


def parse_immediate(regs):
    params = regs.split(", ")
    rd = params[0].replace('R', '')
    rd = bin(int(rd))[2:]
    to_return = f"{rd:>05}"
    rs1 = params[1].replace('R', '')
    rs1 = bin(int(rs1))[2:]
    to_return += f"{rs1:>05}"
    to_return += f"{bin(int(params[2]))[2:]:>016}"
    return to_return


if __name__ == "__main__":
    run()
