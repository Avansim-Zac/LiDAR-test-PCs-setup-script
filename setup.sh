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
cd - 

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
cd ~/pse_heci
cd examples
sudo make
sudo cp pse.c /dio_project
sudo cp pse.h /dio_project
sudo cp heci_types.h /dio_project
cd
cd ~/dio_project
sudo curl -L -o karbon_dio.cpp \
https://raw.githubusercontent.com/Avansim-Zac/LiDAR-test-PCs-setup-script/main/karbon_dio.cpp
sudo gcc -c pse.c -o pse.o
sudo g++ karbon_dio.cpp pse.o -o karbon_dio
echo "--> Created DIO test Project..."

# --------------------------------------------------------
# 11. Inject Global Code::Blocks SFML Project Template
# --------------------------------------------------------
echo "--> Injecting global Code::Blocks SFML template..."

# Global directory where system-wide templates are stored for all users
TEMPLATE_DIR="/usr/share/codeblocks/templates/wizard"
sudo mkdir -p "$TEMPLATE_DIR"

# Generate the template configuration file
sudo tee "$TEMPLATE_DIR/sfml_onlogic.cbpt" > /dev/null << 'EOF'
<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>
<CodeBlocks_template_file>
	<Template title="OnLogic SFML Project" category="Multimedia" notice="Pre-configured template with -pthread and SFML bindings for K410 hardware profiles.">
		<File name="main.cpp" open="1">
<![CDATA[#include <SFML/Graphics.hpp>
#include <iostream>

int main() {
    // Standard 20.04 visual fallback frame
    sf::RenderWindow window(sf::VideoMode(400, 400), "OnLogic SFML Environment");
    sf::CircleShape shape(100.f);
    shape.setFillColor(sf::Color::Green);
    shape.setPosition(100.f, 100.f);

    std::cout << "SFML & Pthread Subsystem Initialised cleanly." << std::endl;

    while (window.isOpen()) {
        sf::Event event;
        while (window.pollEvent(event)) {
            if (event.type == sf::Event::Closed)
                window.close();
        }

        window.clear();
        window.draw(shape);
        window.display();
    }

    return 0;
}
]]>
		</File>
		<Option name="OnLogic SFML Base"/>
		<Project title="SFML_App">
			<Option compiler="gcc"/>
			<Compiler>
				<Add option="-Wall"/>
				<Add option="-std=c++17"/>
				<Add option="-pthread"/>
			</Compiler>
			<Linker>
				<Add library="sfml-graphics"/>
				<Add library="sfml-window"/>
				<Add library="sfml-audio"/>
				<Add library="sfml-network"/>
				<Add library="sfml-system"/>
			</Linker>
			<Unit filename="main.cpp"/>
		</Project>
	</Template>
</CodeBlocks_template_file>
EOF

echo "    [OK] 'OnLogic SFML Project' template injected successfully."

echo "========================================================"
echo " Setup complete! A system REBOOT is required."
echo "========================================================"
