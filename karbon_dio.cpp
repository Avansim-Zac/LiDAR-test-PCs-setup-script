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
    setOutput(fd,0,false);
    setOutput(fd,2,false);
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


    while (true) {
            
        int twilightState = readInput(fd, 3);
        if (twilightState == 0 && twilightState != lastState[3])
        {
            std::cout << "Twlight on " << twilightState << std::endl;
            checkPin = true;
            blinkPin = true;
            lastState[3] = twilightState;
        }
        else if (twilightState == 1 && twilightState != lastState[3])
        {
            std::cout << "Twlight off " << twilightState << std::endl;
            checkPin = false;
            blinkPin = false;
            lastState[3] = twilightState;
        }
        
        bOut = !bOut;
        setOutput(fd, blinkPin ? 3 : 1, bOut);
        setOutput(fd, blinkPin ? 1 : 3, !bOut);
        usleep(100000); // 100 ms polling interval
    }
    close(fd);
    return 0;
}
