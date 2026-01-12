#!/usr/bin/env python3
import sys
import os
import subprocess

def main():
    # Usage: host-ar.py [mode] [archive] [@file-list] ...
    
    args = sys.argv[1:]
    
    if not args:
        print("Error: No arguments provided", file=sys.stderr)
        sys.exit(1)

    # 1. Modify mode string (first argument)
    mode = args[0]
    # Remove 'T' from mode if present (Thin archive not supported by macOS ar)
    new_mode = mode.replace('T', '')
    args[0] = new_mode

    # 2. Expand response files
    new_args = []
    for arg in args:
        if arg.startswith('@'):
            file_path = arg[1:]
            try:
                with open(file_path, 'r') as f:
                    # Read file content, split by whitespace
                    content = f.read().split()
                    new_args.extend(content)
            except Exception as e:
                print(f"Error reading response file {file_path}: {e}", file=sys.stderr)
                sys.exit(1)
        else:
            new_args.append(arg)

    # 3. Call the system ar
    # Use /usr/bin/ar which is standard on macOS
    cmd = ['/usr/bin/ar'] + new_args
    
    # print(f"Invoking: {' '.join(cmd)}")
    
    try:
        subprocess.check_call(cmd)
    except subprocess.CalledProcessError as e:
        sys.exit(e.returncode)

if __name__ == '__main__':
    main()
