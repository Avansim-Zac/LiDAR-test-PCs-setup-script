extern "C" {
#include "pse.h"
#include "heci_types.h"
}

#include <iostream>
#include <unistd.h>

bool setOutput(int fd, uint8_t pin, bool state)
{
    io_command_t cmd =
    {
        .op = state ? kIO_SetOutput : kIO_ClearOutput,
        .dev = kIODev_DO,
        .num = pin
    };

    return pse_command_checked(
        fd,
        kHECI_IO_COMMAND,
        *(uint16_t*)&cmd,
        NULL,
        NULL
    ) == 0;
}

int readInput(int fd, uint8_t pin)
{
    io_command_t cmd =
    {
        .op = kIO_GetInfo,
        .dev = kIODev_DI,
        .num = pin
    };

    heci_body_t body;

    int ret = pse_command_checked(
        fd,
        kHECI_IO_COMMAND,
        *(uint16_t*)&cmd,
        NULL,
        &body
    );

    if(ret <= 0)
        return -1;

    auto* dio =
        reinterpret_cast<heci_dio_info_t*>(body.data);

    return dio->state;
}

int main()
{
    int fd = pse_client_connect();

    if(fd <= 0)
    {
        std::cout << "Failed to connect\n";
        return 1;
    }
    
    std::cout << "Connected\n";
    int lastState[7] = {-1,-1,-1,-1,-1,-1,-1};
    bool bOut = false;

    bool checkPin = false;
    bool blinkPin = false;
    bool aOut = false;
    bool lOn = false;
    bool lOff = true;

    while (true) {     
        
        for (int i = 0;i<4;i++)
        {
            setOutput(fd,i,lOff);
        }       

        std::cout << "Starting Test" << std::endl;
        usleep(1000000);
        std::cout << "Turning on Control light" << std::endl;
        usleep(2000000);
        setOutput(fd,0,lOn);
        usleep(5000000);
        std::cout << "Twlight is off" << std::endl;
        usleep(1000000);
        std::cout << "Turning twlight on" << std::endl;
        usleep(2000000);
        setOutput(fd,2,lOn);
        usleep(5000000);
        std::cout << "Turning bright off" << std::endl;
        usleep(2000000);
        setOutput(fd,0,lOff);
        usleep(5000000);

        std::cout << "Turning twlight off" << std::endl;
        setOutput(fd,2,lOff);
        usleep(5000000);
        std::cout << "Starting bright strobe for 10 cycles" << std::endl;
        usleep(2000000);

        for (int a = 0;a<10;a++)
        {
            setOutput(fd,0,lOn);
            usleep(100000);
            setOutput(fd,0,lOff);
            usleep(100000);
        }
        std::cout << "Bright strobe for 10 cycles complete" << std::endl;
        usleep(1000000);
        std::cout << "Starting dim strobe for 10 cycles" << std::endl;
        usleep(2000000);

        for (int b = 0;b<10;b++)
        {
            setOutput(fd,2,lOn);
            usleep(100000);
            setOutput(fd,2,lOff);
            usleep(100000);
        }
        std::cout << "Dim strobe for 10 cycles complete" << std::endl;
        usleep(1000000);
        std::cout << "Starting alternating strobe for 10 cycles, starting dim" << std::endl;
        usleep(2000000);
        for (int b = 0;b<10;b++)
        {
            setOutput(fd,2,lOn);
            usleep(100000);
            setOutput(fd,2,lOff);
            setOutput(fd,0,lOn);
            usleep(100000);
            setOutput(fd,0,lOff);
            usleep(100000);
        }
        std::cout << "Alternating strobe for 10 cycles complete" << std::endl;
        usleep(1000000);
        std::cout << "Starting Dim toggle strobe for 10 cycles, starting Bright" << std::endl;
        usleep(2000000);
        setOutput(fd,0,lOn);
        for (int b = 0;b<10;b++)
        {
            usleep(100000);
            setOutput(fd,2,lOn);
            usleep(100000);
            setOutput(fd,2,lOff);
        }
        setOutput(fd,0,lOff);
        usleep(2000000);
        std::cout << "Dim toggle strobe for 10 cycles complete" << std::endl;
        usleep(2000000);
        for (int i = 0;i<4;i++)
        {
            setOutput(fd,i,lOff);
        }    
        std::cout << "Test complete, auto exit in 2 seconds" << std::endl;
        usleep(2000000);
        break;
    }
    close(fd);
    return 0;
}
