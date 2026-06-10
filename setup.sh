#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "========================================================"
echo " Starting Standardized Ubuntu 20.04 IoT Developer Setup"
echo " Target Hardware: OnLogic K410"
echo "========================================================"

# --------------------------------------------------------
# 0. System-Wide Update and Package Upgrade
# --------------------------------------------------------
echo "--> Running general system repository update and package upgrade..."
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt update -y
sudo apt upgrade -y
echo "--> Installing curl and git..."
sudo apt install curl -y
sudo apt install git -y

# --------------------------------------------------------
# 1. Update Package Repositories
# --------------------------------------------------------
echo "--> Enabling Universe repository and updating package definitions..."
# Code::Blocks and wxWidgets live in the 'universe' repo, which is disabled by default on some IoT profiles
sudo add-apt-repository -y universe
sudo apt-get update -y

# --------------------------------------------------------
# 2. Install Toolchain & OnLogic Driver Prerequisites
# --------------------------------------------------------
echo "--> Installing C++ toolchain and kernel headers..."
sudo apt-get install -y build-essential cmake git gdb \
    flex bison libssl-dev libelf-dev linux-headers-$(uname -r)

# --------------------------------------------------------
# 3. Install Code::Blocks IDE & C++ GUI Libraries
# --------------------------------------------------------
echo "--> Installing Code::Blocks IDE and wxWidgets packages..."
# libwxgtk3.0-gtk3-0v5 is the corrected 20.04 equivalent for the old wiki dependency
sudo apt-get install -y \
    codeblocks \
    codeblocks-contrib \
    libwxgtk3.0-gtk3-0v5 \
    libwxgtk3.0-gtk3-dev

# --------------------------------------------------------
# 4. Apply OnLogic Kernel Bug Fix (pinctrl_elkhartlake blacklist)
# --------------------------------------------------------
echo 
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
# 5. Download and Install OnLogic PSE Driver
# --------------------------------------------------------
echo "--> Installing OnLogic PSE (IO/CAN/DIO/Serial) Driver..."
sudo git clone https://github.com/onlogic/ubuntu-elkhart-lake-pse-driver.git pse_heci
cd pse_heci
sudo chmod +x install.sh && sudo ./install.sh
cd
cd /home/lidartestrig3
# --------------------------------------------------------
# 5. b. Create a premenant install of the PSE Driver
# --------------------------------------------------------
echo "--> Installing permenant version of OnLogic PSE (IO/CAN/DIO/Serial) Driver..."
sudo apt-get install build-essential flex bison libssl-dev libelf-dev
sudo apt-get install linux-headers-$(uname -r)
echo 'pse' | sudo tee -a /etc/modules-load.d/modules.conf
sudo depmod -a

# --------------------------------------------------------
# 6. Multimedia Capabilities (Display & Text Rendering)
# --------------------------------------------------------
echo "--> Installing Graphics Server and C++ Display libraries..."
# Ubuntu IoT is often bare-bones. If you need an environment to run a GUI, 
# we install a lightweight X11 display server and standard C++ graphics libs.
sudo apt-get install -y xorg xserver-xorg libx11-dev libgl1-mesa-dev

# Installing popular cross-platform C++ frameworks for GUI/Text/Windowing
sudo apt-get install -y libsdl2-dev libsfml-dev

# --------------------------------------------------------
# 7. Audio Capabilities (Voice & SFX .WAV playback)
# --------------------------------------------------------
echo "--> Installing Audio subsystems and C++ audio frameworks..."
sudo apt-get install -y alsa-utils pulseaudio libasound2-dev

# Extensions for loading/playing WAV files gracefully in C++
sudo apt-get install -y libsndfile1-dev libsdl2-mixer-dev

# --------------------------------------------------------
# 8. Networking & Bluetooth Peer-to-Peer
# --------------------------------------------------------
echo "--> Installing Bluetooth stack and native BlueZ C++ headers..."
sudo apt-get install -y bluez bluez-tools libbluetooth-dev curl net-tools

# --------------------------------------------------------
# 9. User Permission Matrix & Udev Rule (Crucial QoL step)
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

# --------------------------------------------------------
# 10. Create DIO test Project
# --------------------------------------------------------
echo "--> Creating DIO test Project..."
sudo mkdir dio_project
cd /home/lidartestrig3/pse_heci
cd examples
sudo make
sudo cp pse.c /home/lidartestrig3/dio_project
sudo cp pse.h /home/lidartestrig3/dio_project
sudo cp heci_types.h /home/lidartestrig3/dio_project
cd
cd /home/lidartestrig3/dio_project
sudo curl -L -o karbon_dio.cpp \
https://raw.githubusercontent.com/Avansim-Zac/LiDAR-test-PCs-setup-script/main/karbon_dio.cpp
sudo gcc -c pse.c -o pse.o
sudo g++ karbon_dio.cpp pse.o -o karbon_dio
echo "--> Created DIO test Project..."

echo "========================================================"
echo " Setup complete! A system REBOOT is required."
echo "========================================================"
