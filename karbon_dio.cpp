extern "C" {
#include "pse.h"
#include "heci_types.h"
}

#include <iostream>
#include <unistd.h>
#include <chrono>

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
    auto lastBlinkChange = std::chrono::steady_clock::now();
    const auto blinkOnDuration  = std::chrono::milliseconds(300);
    const auto blinkOffDuration = std::chrono::milliseconds(100);

    int lastDimSwitch = -1;
    int blinkPin = 1;
    int checkPin = 0;
    bool lastAnyActive = false; // tracks the combined state of inputs 0,1,2,4,5,6


    while (true) {
        bool anyActive = false; // recomputed fresh each pass
        bool forceUpdate = false;

        for (int i = 0; i < 7; i++) {
            int inputState = readInput(fd, i);

            if (inputState < 0) {
                std::cout << "Failed to read input " << i << "\n";
                continue; // don't let one bad read skip the rest, including input 3
            }

            if (i == 3) {
                int dimSwitch = inputState;

                if (dimSwitch != lastDimSwitch) {
                    if (dimSwitch == 0) {
                        std::cout << "Twilight active" << std::endl;
                        blinkPin = 3;
                        checkPin = 2;
                        setOutput(fd, 0, true); // off
                        setOutput(fd, 1, true);
                    }
                    else if (dimSwitch == 1) {
                        std::cout << "Twilight disabled" << std::endl;
                        blinkPin = 1;
                        checkPin = 0;
                        setOutput(fd, 2, true); // off
                        setOutput(fd, 3, true);
                    }
                    lastDimSwitch = dimSwitch;
                    forceUpdate = true;
                }
                continue; // input 3 doesn't participate in the mirror aggregate
            }

            // inputState == 0 mean on
            if (inputState == 0) {
                anyActive = true;
            }

            lastState[i] = inputState;
        }

        // Only touch the output when the combined state actually changes
        if (anyActive != lastAnyActive || forceUpdate) {
            bool ok = setOutput(fd, checkPin, !anyActive);

            std::cout << "Combined switch state = " << (anyActive ? "ACTIVE" : "IDLE")
                       << ", Output " << checkPin << " set to "
                       << (anyActive ? "ON" : "OFF")
                       << std::endl;

            lastAnyActive = anyActive;
        }

        // Asymmetric blink: 200ms on, 100ms off
        auto now = std::chrono::steady_clock::now();
        auto elapsed = now - lastBlinkChange;
        auto threshold = bOut ? blinkOnDuration : blinkOffDuration;

        if (elapsed >= threshold) {
            bOut = !bOut;
            setOutput(fd, blinkPin, bOut);
            lastBlinkChange = now;
        }

        usleep(10000); // 10 ms main loop tick, keeps switch polling responsive
    }
    close(fd);
    return 0;
}
