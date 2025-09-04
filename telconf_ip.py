import re
import subprocess
from time import sleep

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
    output = subprocess.check_output(['ip', 'addr', 'show', 'tun0'], text=True)
    match = re.search(r'inet (\d+\.\d+\.\d+\.\d+)', output)
    if match:
        return match.group(1)
    raise ValueError("IP address for tun0 not found")

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
        subprocess.run(['xsel', '--clipboard', '--input'], input=text.encode(), check=True)
        subprocess.run(['xsel', '--primary', '--input'], input=text.encode(), check=True)
        print(f"IP copied to clipboard: {text}")
    except Exception as e:
        print(f"Failed to copy to clipboard: {e}")


def main():
    old_ip = get_old_ip(CONFIG_PATH)
    new_ip = get_tun0_ip()
    if old_ip != new_ip:
        count = replace_ip_in_file(CONFIG_PATH, old_ip, new_ip)
        print(f"{count} replaced {old_ip} -> {new_ip}")
    else:
        print("IP addresses are the same, no change made.")

    copy_to_clipboard(new_ip)

    sleep(5)

if __name__ == "__main__":
    main()