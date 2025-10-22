#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <termios.h>
#include <errno.h>

#define SERIAL_PORT "/dev/ttyUSB0"  
#define BAUDRATE B115200

char *convert2char(unsigned char val)
{
    char *array_string[] = {"-1", "A", "B", "Z", "Start", "Up", "Down", "Left", "Right", "N/A", "C-UP", "L", "R", "N/A", "C-DOWN", "C-LEFT", "C-RIGHT",  "X-1", "X-2", "X-3", "X-4","X-5", "X-6",
    "X-7", "X-8", "Y-1", "Y-2", "Y-3", "Y-4","Y-5", "Y-6", "Y-7", "Y-8"};

    if (val >= 33)
        return "unknown";

    return array_string[val];
}

int main() {
    int serial_fd;
    struct termios tty;
    char read_buf[10];
    int num_bytes;

    // Open the serial port
    serial_fd = open(SERIAL_PORT, O_RDWR | O_NOCTTY); 
    if (serial_fd == -1) {
        perror("Error opening serial port");
        return 1;
    }

    if (tcgetattr(serial_fd, &tty) != 0) {
        perror("Error getting tty attributes");
        return 1;
    }

    cfsetispeed(&tty, BAUDRATE);
    cfsetospeed(&tty, BAUDRATE);

    tty.c_cflag = (tty.c_cflag & ~CSIZE) | CS8; 
    tty.c_iflag &= ~IGNBRK;                     
    tty.c_lflag = 0;                            
    tty.c_oflag = 0;                            
    tty.c_cc[VMIN]  = 1;                        
    tty.c_cc[VTIME] = 1;                        

    tty.c_iflag &= ~(IXON | IXOFF | IXANY);     
    tty.c_cflag |= (CLOCAL | CREAD);            
    tty.c_cflag &= ~(PARENB | PARODD);          
    tty.c_cflag &= ~CSTOPB;                     
    tty.c_cflag &= ~CRTSCTS;                    

    if (tcsetattr(serial_fd, TCSANOW, &tty) != 0) {
        perror("Error from tcsetattr");
        return 1;
    }

    
    memset(read_buf, 0, sizeof(read_buf));
    char last_val[50] = "ispis";
    while (1) {
        num_bytes = read(serial_fd, read_buf, sizeof(read_buf));
        if (num_bytes > 0) {
            for (int i = 0; i < num_bytes; i++) {
                char *new_val = convert2char(read_buf[i]);
                char *unknown = "unknown";
                if(!strcmp(unknown, new_val))
                    continue;
                if(strcmp(last_val, new_val))
                {
                    printf("Poslednji pritisnut taster je %s\n", new_val);  
                    strcpy(last_val, new_val);
                }
            }
        } else if (num_bytes < 0) {
            perror("read");
            break;
        }    
    }

    close(serial_fd);
    return 0;
}
