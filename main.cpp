extern "C" {
#include "pse.h"
}

#include <unistd.h>
#include <iostream>

int main()
{
    int fd = pse_client_connect();

    if (fd <= 0)
    {
        std::cout << "Connection failed\n";
        return 1;
    }

    io_command_t command =
    {
        .op = kIO_SetOutput,
        .dev = kIODev_DO,
        .num = 0
    };

    int result = pse_command_checked(
        fd,
        kHECI_IO_COMMAND,
        *(uint16_t*)&command,
        NULL,
        NULL);

    std::cout << "Result = " << result << std::endl;

    close(fd);
}
