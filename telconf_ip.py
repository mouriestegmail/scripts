import re
import subprocess
from time import sleep
import platform

CONFIG_PATH = "/opt/ringcentral/tel/config/tel.conf"

def get_old_ip(path):
    with open(path, 'r') as f:
        lines = [next(f) for _ in range(20)]
    for line in lines:
        match = re.match(r"IPAddress=(\d+\.\d+\.\d+\.\d+)", line)
        if match:
            return match.group(1)
    raise ValueError("IPAddress not found in first 20 lines")

def get_tun0_ip():
    output = subprocess.check_output(['ip', 'addr', 'show', 'utun6'], text=True)
    match = re.search(r'inet (\d+\.\d+\.\d+\.\d+)', output)
    if match:
        return match.group(1)
    raise ValueError("IP address for tun0 not found")

import re

def get_utun_ip(interface="utun6"):
    output = subprocess.check_output(["ifconfig", interface], text=True)
    match = re.search(r"inet (\d+\.\d+\.\d+\.\d+)", output)
    if match:
        return match.group(1)
    raise ValueError(f"IP address for {interface} not found")

def replace_ip_in_file(path, old_ip, new_ip):
    with open(path, 'r') as f:
        content = f.read()
    new_content, count = re.subn(re.escape(old_ip), new_ip, content)
    if count > 0:
        with open(path, 'w') as f:
            f.write(new_content)
    return count

def copy_to_clipboard(text):
    try:
        system = platform.system()
        if system == "Darwin":  # macOS
            subprocess.run("pbcopy", input=text.encode(), check=True)
        elif system == "Linux":  # Linux
            subprocess.run(['xsel', '--clipboard', '--input'], input=text.encode(), check=True)
            subprocess.run(['xsel', '--primary', '--input'], input=text.encode(), check=True)
        else:
            raise NotImplementedError(f"Clipboard copy not implemented for {system}")

        print(f"IP copied to clipboard: {text}")
    except Exception as e:
        print(f"Failed to copy to clipboard: {e}")


def main():
    old_ip = get_old_ip(CONFIG_PATH)
    new_ip = get_utun_ip("utun6")
    if old_ip != new_ip:
        count = replace_ip_in_file(CONFIG_PATH, old_ip, new_ip)
        print(f"{count} replaced {old_ip} -> {new_ip}")
    else:
        print("IP addresses are the same, no change made.")

    copy_to_clipboard(new_ip)

    sleep(5)

if __name__ == "__main__":
    main()