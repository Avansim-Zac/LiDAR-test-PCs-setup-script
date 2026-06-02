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

Bash
#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "========================================================"
echo " Starting Standardized Ubuntu 20.04 IoT Developer Setup"
echo " Target Hardware: OnLogic K410"
echo "========================================================"

# --------------------------------------------------------
# 1. Update Package Repositories
# --------------------------------------------------------
echo "--> Updating system package definitions..."
sudo apt-get update -y

# --------------------------------------------------------
# 2. Install Toolchain & OnLogic Driver Prerequisites
# --------------------------------------------------------
echo "--> Installing C++ toolchain and kernel headers..."
sudo apt-get install -y build-essential cmake git gdb \
    flex bison libssl-dev libelf-dev linux-headers-$(uname -r)

# --------------------------------------------------------
# 3. Apply OnLogic Kernel Bug Fix (pinctrl_elkhartlake blacklist)
# --------------------------------------------------------
echo "--> Checking/Applying GRUB blacklist patch for Elkhart Lake..."
# The pinctrl_elkhartlake driver is known to timeout on startup/shutdown. 
# We append the blacklist rule to the default kernel command line.
if ! grep -q "modprobe.blacklist=pinctrl_elkhartlake" /etc/default/grub; then
    sudo sed -i 's/\(GRUB_CMDLINE_LINUX_DEFAULT=".*\)"/\1 modprobe.blacklist=pinctrl_elkhartlake"/' /etc/default/grub
    sudo update-grub
    echo "    [OK] GRUB updated with driver blacklist workaround."
else
    echo "    [SKIP] GRUB already contains the blacklist patch."
fi

# --------------------------------------------------------
# 4. Download and Install OnLogic PSE Driver
# --------------------------------------------------------
echo "--> Installing OnLogic PSE (IO/CAN/DIO/Serial) Driver..."
BUILD_DIR="$HOME/pse_driver_build"

if [ ! -d "$BUILD_DIR" ]; then
    git clone https://github.com/onlogic/ubuntu-elkhart-lake-pse-driver.git "$BUILD_DIR"
    cd "$BUILD_DIR"
    sudo chmod +x install.sh
    # Executes the automated check, build, and module insertion script provided by OnLogic
    sudo ./install.sh
    echo "    [OK] PSE Driver module built and inserted successfully."
else
    echo "    [SKIP] PSE driver build directory already exists."
fi

# --------------------------------------------------------
# 5. Multimedia Capabilities (Display & Text Rendering)
# --------------------------------------------------------
echo "--> Installing Graphics Server and C++ Display libraries..."
# Ubuntu IoT is often bare-bones. If you need an environment to run a GUI, 
# we install a lightweight X11 display server and standard C++ graphics libs.
sudo apt-get install -y xorg xserver-xorg libx11-dev libgl1-mesa-dev

# Installing popular cross-platform C++ frameworks for GUI/Text/Windowing (Choose what you prefer)
sudo apt-get install -y libsdl2-dev libsfml-dev

# --------------------------------------------------------
# 6. Audio Capabilities (Voice & SFX .WAV playback)
# --------------------------------------------------------
echo "--> Installing Audio subsystems and C++ audio frameworks..."
sudo apt-get install -y alsa-utils pulseaudio libasound2-dev

# Extensions for loading/playing WAV files gracefully in C++
sudo apt-get install -y libsndfile1-dev libsdl2-mixer-dev

# --------------------------------------------------------
# 7. Networking & Bluetooth Peer-to-Peer
# --------------------------------------------------------
echo "--> Installing Bluetooth stack and native BlueZ C++ headers..."
sudo apt-get install -y bluez bluez-tools libbluetooth-dev curl net-tools

# --------------------------------------------------------
# 8. User Permission Matrix & Udev Rule (Crucial QoL step)
# --------------------------------------------------------
echo "--> Configuring user permission groups..."
# Add user to standard hardware pools so you don't run into permission blocks
sudo usermod -aG audio $USER
sudo usermod -aG bluetooth $USER
sudo usermod -aG dialout $USER

# FIXING DEV PERMISSIONS: OnLogic documentation notes that opening /dev/pse fails unless you are root.
# Running your C++ application binaries using 'sudo' during development breaks IDE debugging (like VS Code).
# We inject a custom Udev rule to assign /dev/pse to the 'dialout' group automatically.
echo "--> Injecting custom Udev rule for /dev/pse..."
echo 'KERNEL=="pse", MODE="0660", GROUP="dialout"' | sudo tee /etc/udev/rules.d/99-pse.rules

echo "========================================================"
echo " Setup complete! A system REBOOT is required."
echo "========================================================"
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
