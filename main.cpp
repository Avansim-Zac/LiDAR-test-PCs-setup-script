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

    setOutput(fd, 0, true);

    sleep(2);

    setOutput(fd, 0, false);

    close(fd);

    return 0;
}
