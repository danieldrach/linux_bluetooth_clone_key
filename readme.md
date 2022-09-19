# Run this at your own risk.
This is a bash script created for myself and works in my personal machine running Ubuntu 20.04 and Windows 10 installed in 2 different hard drives. I am not experienced in Linux and neither in bash and the code was hastly cobbled together for my personal purposes.  So it probably doesn't adhere to bash's best practices, use it at your own risk. 

I just decided to share it as it might be useful to someone else, be aware that it might not work in your current configuration since I haven´t convered any diferent configurations and the exceptions that might steam from running the script in a machine different from my own PC. Feel free to modify it and please provide feedback if there are improvements to be made. 

# Purpose of the script
To help provide seamless bluetooth connectivity on dual-boot computers featuring both Linux and Windows installations. The problem this script helps to address is that when one of the operating systems negotiates a key with some bluetooth device X the other OS is unaware of that key, and since device X can only remember one key per MAC address the usage of any bluetooth device can become cumbersome in dual-boot systems requiring a new pairing at each reboot.

This script detects a windows partition present in a drive attached to the same machine in which the linux instalation resides. Mounts that partition, accesses the windows registry and clones the key for the selected device that was negotiated in windows so that it can be used inside the Linux OS as well. The scripts basically implements the procedure outlined in [THIS GUIDE](https://github.com/spxak1/weywot/blob/main/guides/bt_dualboot.md).

# How to use
The sequence of steps to make it work is: 

1. Pair the bluetooth device in Linux.
2. Reboot the computer into Windows.
3. Pair the same device in windows.
4. Reboot into linux (now your device won't be working anymore).
5. Run the scrip with the command `./clone_bt_key.sh`.
6. Select the desired bluetooth device.
7. If needed log out and in again, now your device should work seemlessly between in both Windows and Linux, without need for constant pairing.

# Dependencies
Used `reged` to read the contents of the Windows registry, this and any other dependency used can probably be easily installed using the native package manager for you Linux distribution.
