# LiDAR-test-PCs-setup-script
Run this script from the terminal to automatically install all required software and dependencies.

To run this script, enter the following into the terminal:

sudo apt install curl -y


sudo curl -sSL https://raw.githubusercontent.com/Avansim-Zac/LiDAR-test-PCs-setup-script/main/setup.sh | sudo bash

Disabled Sleep states for Karbon: sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

To rebuild the karbon_dio test script use the following commands to grab either input test, or auto led test:

Auto:

sudo curl -sSL https://raw.githubusercontent.com/Avansim-Zac/LiDAR-test-PCs-setup-script/main/karbon_dioLEDAutoTestRebuild.sh | sudo bash

Input:

sudo curl -sSL https://raw.githubusercontent.com/Avansim-Zac/LiDAR-test-PCs-setup-script/main/karbon_dioRebuild.sh | sudo bash

Below is a reference of the IO pins available for external hardware. 
<img width="770" height="484" alt="Onlogic GPIO" src="https://github.com/user-attachments/assets/8dfde867-de33-4ecd-9f58-7a230290f1ea" />
