#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "========================================================"
echo " Starting karbon_dio rebuild"
echo " Target script: karbon_dioLEDAutoTest.cpp"
echo "========================================================"

cd
USER_HOME=$(eval echo ~${SUDO_USER})
cd ${USER_HOME}
echo "--> Removing current DIO test project"
sudo rm -r ${USER_HOME}/kono_dio_da_project
echo "--> Creating DIO test project folder..."
cd
cd ${USER_HOME}
sudo mkdir kono_dio_da_project
cd
echo "--> Copying dependecies to DIO test project folder..."
cd ${USER_HOME}/pse_heci
cd examples
sudo make
sudo cp pse.c ${USER_HOME}/kono_dio_da_project
sudo cp pse.h ${USER_HOME}/kono_dio_da_project
sudo cp heci_types.h ${USER_HOME}/kono_dio_da_project
cd
echo "--> Building script"
cd ${USER_HOME}/kono_dio_da_project
sudo curl -L -o karbon_dio.cpp \
https://raw.githubusercontent.com/Avansim-Zac/LiDAR-test-PCs-setup-script/main/karbon_dioLEDAutoTest.cpp
sudo gcc -c pse.c -o pse.o
sudo g++ karbon_dio.cpp pse.o -o karbon_dio
echo "--> Created DIO test Project..."
echo "--> Running DIO test Project..."
sudo ./karbon_dio
