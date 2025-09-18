
#pragma once

typedef int pin_name_t;
typedef int err_t;
typedef int uart_data_bits_t;

#define Delay_100ms() vTaskDelay(100 / portTICK_PERIOD_MS) 
#define Delay_1sec() vTaskDelay(1000 / portTICK_PERIOD_MS)

#define log_error(logger, msg) printf("ERROR: " msg)