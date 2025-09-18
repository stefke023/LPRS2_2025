

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_system.h"
#include "esp_log.h"
#include "driver/uart.h"
#include "string.h"
#include "driver/gpio.h"

//TODO Header
/**
 * @brief LR 14 control commands.
 * @details Specified setting for control commands of LR 14 Click driver.
 */
 #define LR14_CMD_AT                                 "AT"
 #define LR14_CMD_TOGGLE_ECHO                        "ATE"
 #define LR14_CMD_FACTORY_RESET                      "ATR"
 #define LR14_CMD_GET_MODEL_ID                       "AT+HWMODEL"
 #define LR14_CMD_GET_FW_VERSION                     "AT+VER"
 #define LR14_CMD_GET_SERIAL_NUMBER                  "AT+SN"
 #define LR14_CMD_NETWORK_WORK_MODE                  "AT+NWM"
 #define LR14_CMD_P2P_MODE_FREQUENCY                 "AT+PFREQ"
 #define LR14_CMD_P2P_MODE_SPREADING_FACTOR          "AT+PSF"
 #define LR14_CMD_P2P_MODE_BANDWIDTH                 "AT+PBW"
 #define LR14_CMD_P2P_MODE_CODE_RATE                 "AT+PCR"
 #define LR14_CMD_P2P_MODE_PREAMBLE_LENGTH           "AT+PPL"
 #define LR14_CMD_P2P_MODE_TX_POWER                  "AT+PTP"
 #define LR14_CMD_P2P_RX_MODE                        "AT+PRECV"
 #define LR14_CMD_P2P_TX_MODE                        "AT+PSEND"
 
 /**
  * @brief LR 14 device response for AT commands.
  * @details Device response after commands.
  */
 #define LR14_RSP_OK                                 "OK"
 #define LR14_RSP_ERROR                              "AT_ERROR"
 #define LR14_RSP_PARAM_ERROR                        "AT_PARAM_ERROR"
 #define LR14_RSP_BUSY_ERROR                         "AT_BUSY_ERROR"
 #define LR14_RSP_TEST_PARAM_OVERFLOW                "AT_TEST_PARAM_OVERFLOW"
 #define LR14_RSP_NO_CLASSB_ENABLE                   "AT_NO_CLASSB_ENABLE"
 #define LR14_RSP_NO_NETWORK_JOINED                  "AT_NO_NETWORK_JOINED"
 #define LR14_RSP_RX_ERROR                           "AT_RX_ERROR"
 #define LR14_RSP_INITIAL                            "----------------------"
 
 /**
  * @brief LR 14 device events settings.
  * @details Device events settings.
  */
 #define LR14_EVT_RX_P2P                             "+EVT:RXP2P"
 #define LR14_EVT_RX_P2P_ERROR                       "+EVT:RXP2P RECEIVE ERROR"
 #define LR14_EVT_RX_P2P_TIMEOUT                     "+EVT:RXP2P RECEIVE TIMEOUT"
 #define LR14_EVT_TX_P2P                             "+EVT:TXP2P"
 
 /**
  * @brief LR 14 driver buffer size.
  * @details Specified size of driver ring buffer.
  * @note Increase buffer size if needed.
  */
 #define LR14_TX_DRV_BUFFER_SIZE                     200
 #define LR14_RX_DRV_BUFFER_SIZE                     600
 

static const int RX_BUF_SIZE = 1024;

// Default
//#define TXD_PIN (GPIO_NUM_4)
//#define RXD_PIN (GPIO_NUM_5)
// Symbol
#define TXD_PIN (GPIO_NUM_5)
#define RXD_PIN (GPIO_NUM_4)



void init(void)
{
    const uart_config_t uart_config = {
        .baud_rate = 115200,
        .data_bits = UART_DATA_8_BITS,
        .parity = UART_PARITY_DISABLE,
        .stop_bits = UART_STOP_BITS_1,
        .flow_ctrl = UART_HW_FLOWCTRL_DISABLE,
        .source_clk = UART_SCLK_DEFAULT,
    };
    // We won't use a buffer for sending data.
    uart_driver_install(UART_NUM_1, RX_BUF_SIZE * 2, 0, 0, NULL, 0);
    uart_param_config(UART_NUM_1, &uart_config);
    uart_set_pin(UART_NUM_1, TXD_PIN, RXD_PIN, UART_PIN_NO_CHANGE, UART_PIN_NO_CHANGE);
}

int sendData(const char* logName, const char* data)
{
    const int len = strlen(data);
    const int txBytes = uart_write_bytes(UART_NUM_1, data, len);
    ESP_LOGI(logName, "Wrote %d bytes", txBytes);
    return txBytes;
}

static void tx_task(void *arg)
{
    static const char *TX_TASK_TAG = "TX_TASK";
    esp_log_level_set(TX_TASK_TAG, ESP_LOG_INFO);
    while (1) {
        sendData(TX_TASK_TAG, LR14_CMD_AT "\r\n\0");
        vTaskDelay(2000 / portTICK_PERIOD_MS);
    }
}

static void rx_task(void *arg)
{
    static const char *RX_TASK_TAG = "RX_TASK";
    esp_log_level_set(RX_TASK_TAG, ESP_LOG_INFO);
    uint8_t* data = (uint8_t*) malloc(RX_BUF_SIZE + 1);
    while (1) {
        const int rxBytes = uart_read_bytes(UART_NUM_1, data, RX_BUF_SIZE, 1000 / portTICK_PERIOD_MS);
        if (rxBytes > 0) {
            data[rxBytes] = 0;
            ESP_LOGI(RX_TASK_TAG, "Read %d bytes: '%s'", rxBytes, data);
            ESP_LOG_BUFFER_HEXDUMP(RX_TASK_TAG, data, rxBytes, ESP_LOG_INFO);
        }
    }
    free(data);
}

void app_main(void)
{
    init();
    xTaskCreate(rx_task, "uart_rx_task", 1024 * 2, NULL, configMAX_PRIORITIES - 1, NULL);
    xTaskCreate(tx_task, "uart_tx_task", 1024 * 2, NULL, configMAX_PRIORITIES - 2, NULL);
}
