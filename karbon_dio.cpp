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


    while (true) {
            
        int twilightState = readInput(fd, 3);
        if (twilightState == 0 && twilightState != lastState[3])
        {
            std::cout << "Twlight on" << std::endl;
            checkPin = true;
            blinkPin = true;
            lastState[3] = twilightState;
        }
        else if (twilightState == 1 && twilightState != lastState[3])
        {
            std::cout << "Twlight off" << std::endl;
            checkPin = false;
            blinkPin = false;
            lastState[3] = twilightState;
        }
        for (int i =0;i<7;i++)
        {
            int inputState = readInput(fd, i);

            if (inputState < 0) 
            {
                std::cout << "Failed to read input "<< i <<"\n";
                continue;
            }

            if (inputState != lastState[i])
            {
                bool ok = inputState == 0;
                setOutput(fd, checkPin ? 2 : 0, ok ? 1 : 0);
                
                std::cout << "Input " << i << " = " << inputState
                            << ", Output " << (checkPin ? 2 : 0) << " set to "
                            << (inputState ? "OFF" : "ON")
                            << ", Result = " << ok
                            << std::endl;
                if (i !=3)
                {
                    lastState[i] = inputState;
                }
            }
        }
        bOut = !bOut;
        setOutput(fd, blinkPin ? 3 : 1, bOut);
        setOutput(fd, checkPin ? 0 : 2, false);
        setOutput(fd, blinkPin ? 1 : 3, false);
        usleep(100000); // 100 ms polling interval
    }
    close(fd);
    return 0;
}
