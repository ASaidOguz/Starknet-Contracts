#!/usr/bin/env python3
"""
Starknet ByteArray Converter CLI

A command-line utility for converting between bytearray/felts and strings for Starknet.
"""

import sys
import argparse
import re
""" USAGE::python3 b_convert.py --mode felt2str --input "[0x2, 0x68747470733a2f2f697066732e696f2f69706673
2f516d646e323837666757, 0x387367456a64476a5858426258786846585a67383861657043717033386d36, 0x6551623539, 0x5]"
# Example output:
https://ipfs.io/ipfs/Qmdn287fgW8sgEjdGjXXBbXxhFXZg88aepCqp38m6eQb59 """

def felt_to_string(felt):
    """Convert a StarkNet felt to a string"""
    byte_length = (felt.bit_length() + 7) // 8
    bytes_data = felt.to_bytes(byte_length, 'big')
    return bytes_data.decode('ascii')


def string_to_felt(text):
    """Convert a string to a StarkNet felt"""
    bytes_data = bytes(text, 'ascii')
    return int.from_bytes(bytes_data, 'big')


def felt_array_to_string(felt_array):
    """Convert an array of StarkNet felts to a string"""
    result = ""
    for felt in felt_array:
        if felt == 0:  # Skip 0 values which may be padding or length indicators
            continue
        try:
            result += felt_to_string(felt)
        except:
            pass  # Skip felts that can't be decoded
    return result


def string_to_felt_array(text, chunk_size=31):
    """Convert a string to an array of StarkNet felts"""
    result = []
    for i in range(0, len(text), chunk_size):
        chunk = text[i:i+chunk_size]
        felt = string_to_felt(chunk)
        result.append(felt)
    return result


def bytearray_to_string(byte_array, encoding='utf-8'):
    """Convert a ByteArray to a string"""
    return byte_array.decode(encoding)


def string_to_bytearray(text, encoding='utf-8'):
    """Convert a string to a ByteArray"""
    return bytearray(text, encoding)


def parse_felt_array(felt_str):
    """Parse a string representation of felt array from various formats"""
    felts = []
    
    # Remove outer brackets if present
    felt_str = felt_str.strip()
    if felt_str.startswith('[') and felt_str.endswith(']'):
        felt_str = felt_str[1:-1].strip()
    
    # Try to extract hex or decimal values using regex
    hex_pattern = r'0x[0-9a-fA-F]+'
    hex_matches = re.findall(hex_pattern, felt_str)
    
    for match in hex_matches:
        felts.append(int(match, 16))
    
    # If no hex matches found, try parsing it as a comma-separated list
    if not felts:
        parts = felt_str.split(',')
        for part in parts:
            part = part.strip()
            if part.startswith('0x'):
                felts.append(int(part, 16))
            else:
                try:
                    felts.append(int(part))
                except:
                    pass  # Skip invalid parts
    
    return felts


def main():
    parser = argparse.ArgumentParser(description='Starknet ByteArray Converter')
    parser.add_argument('--mode', '-m', choices=['felt2str', 'str2felt', 'decode-sncast'], 
                        required=True, help='Conversion mode')
    parser.add_argument('--input', '-i', required=True, 
                        help='Input data (string, felt, or array of felts). For array input, quote the entire array.')
    parser.add_argument('--encoding', '-e', default='utf-8', 
                        help='String encoding (default: utf-8)')
    parser.add_argument('--skip-first', '-s', action='store_true',
                        help='Skip the first felt in the array (often a length indicator)')
    
    args = parser.parse_args()
    
    try:
        if args.mode == 'felt2str' or args.mode == 'decode-sncast':
            # Check if input looks like an array (contains brackets or commas)
            if '[' in args.input or ',' in args.input:
                felt_arr = parse_felt_array(args.input)
                
                # Skip the first felt if requested (often a length indicator in Starknet responses)
                if args.skip_first and felt_arr:
                    felt_arr = felt_arr[1:]
                
                result = felt_array_to_string(felt_arr)
            else:
                # Parse single felt
                if args.input.startswith('0x'):
                    felt = int(args.input, 16)
                else:
                    felt = int(args.input)
                
                result = felt_to_string(felt)
            
            print(result)
            
        elif args.mode == 'str2felt':
            result = string_to_felt(args.input)
            print(f"Decimal: {result}")
            print(f"Hex: 0x{result:x}")
            
            # Also show as felt array (useful for longer strings)
            felt_arr = string_to_felt_array(args.input)
            print("\nAs felt array:")
            print("Decimal:", felt_arr)
            print("Hex:", [f"0x{felt:x}" for felt in felt_arr])
            
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()