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
