# LiDAR-test-PCs-setup-script
Run this script from the terminal to automatically install all required software and dependencies.


I prompted Gemini with the following: 

we will need to have the following capabilities:
Our requirements are:
Display graphical images and text on screen
Access to the PCs IO
Play sounds (voice and sfx, as wavs)
Network capabilities
Bluetooth peer-to-peer
Probably more :)

We will be developing in C++, and are running Ubuntu 20.04 IOT on Onlogic k410s. To get the IO working, we need to follow the following guide: https://support.onlogic.com/support-articles/how-tos/operating-systems/pse-configuration-ubuntu

Please advise on the next steps to create a script to install all of this 
-------------------------------------------------------
Annd got this response 
-------------------------------------------------------
Using a shell script hosted on a GitHub repository is an excellent way to automate this. Because you are using an Intel Elkhart Lake-based system (the OnLogic K410) with Ubuntu 20.04 IoT, your script must handle standard C++ libraries alongside low-level kernel patching, driver compilation, and user permission alignment.

The OnLogic guide notes that the Programmable Services Engine (PSE) driver requires matching kernel headers, a specific GRUB fix to prevent a startup timeout/crash bug, and root privileges by default to interface with /dev/pse.

A production-ready Bash script (setup.sh) addresses all your requirements sequentially.

The Unified Setup Script (setup.sh)
Create a script named setup.sh and commit it to your GitHub repository:


Deep Dive: What This Script Fixes Behind the Scenes
Kernel Target Stability: Because you are on Ubuntu 20.04 IoT, you run the dedicated Intel IoT kernel architecture (5.13-intel or 5.15-intel). The script dynamically targets your current operating kernel by passing linux-headers-$(uname -r) directly into apt-get before compiling the OnLogic driver.

The pinctrl Crash Workaround: The regex string substitution block targets your system's /etc/default/grub configuration file. It securely appends modprobe.blacklist=pinctrl_elkhartlake right before the terminating quote of your boot sequence parameters and refreshes the system state via update-grub.

Eliminating the sudo requirement for C++ Applications: The OnLogic documentation highlights that opening /dev/pse under standard runtime constraints results in a permission failure. The bottom block creates a persistent hardware rule (99-pse.rules). When the system maps the /dev/pse hardware character device file at boot, it binds it to the dialout user group. Because your developers belong to that group, they can open the IO streams natively without running their executable as root.

C++ Capabilities Injection:

Display/Text: libsdl2-dev or libsfml-dev gives your C++ app immediate access to window creation, text rendering, and frame buffers over Mesa/OpenGL.

Audio: libsndfile1-dev allows parsing .wav audio files directly into sound memory buffers, while libasound2-dev interfaces natively with the Linux ALSA layer.

Bluetooth P2P: libbluetooth-dev injects the core BlueZ header architecture (<bluetooth/bluetooth.h>, <bluetooth/rfcomm.h>) so your app can spin up native Linux sockets for local device discovery and peer data transfer.

Next Steps to Deploy
Once you have reviewed the packages and verified that your selected C++ engine matches the graphics libraries installed (e.g., SDL2, SFML, or custom OpenGL), perform the following on your fleet:

Host the Script: Push the setup.sh file to a public or private GitHub repository.

Run on Target Machines: When a new K410 hardware block arrives, drop to the terminal window and fetch the file remotely:

Bash
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/setup.sh | bash
Reboot the System: sudo reboot now to commit the blacklisted driver changes and load the newly compiled pse.ko kernel extension module.

Verify the State: To verify everything loaded into memory correctly, run:

Bash
lsmod | grep pse
ls -la /dev/pse
(You should see the driver active and /dev/pse belonging to the dialout group with read/write permissions active).
