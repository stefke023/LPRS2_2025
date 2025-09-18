/****************************************************************************
** Copyright (C) 2020 MikroElektronika d.o.o.
** Contact: https://www.mikroe.com/contact
**
** Permission is hereby granted, free of charge, to any person obtaining a copy
** of this software and associated documentation files (the "Software"), to deal
** in the Software without restriction, including without limitation the rights
** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
** copies of the Software, and to permit persons to whom the Software is
** furnished to do so, subject to the following conditions:
** The above copyright notice and this permission notice shall be
** included in all copies or substantial portions of the Software.
**
** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
** EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
** OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
** IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
** DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT
** OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
**  USE OR OTHER DEALINGS IN THE SOFTWARE.
****************************************************************************/

/*!
 * @file lr14.c
 * @brief LR 14 Click Driver.
 */

#include "lr14.h"

void lr14_cfg_setup ( lr14_cfg_t *cfg ) 
{
    // Communication gpio pins
    cfg->rx_pin = GPIO_NUM_4;
    cfg->tx_pin = GPIO_NUM_5;


    // Additional gpio pins
    cfg->rst = -1;

    cfg->baud_rate     = 115200;
    cfg->data_bit      = UART_DATA_8_BITS;
    cfg->parity_bit    = UART_PARITY_DISABLE;
    cfg->stop_bit      = UART_STOP_BITS_1;
    cfg->uart_blocking = false;
}

err_t lr14_init ( lr14_t *ctx, lr14_cfg_t *cfg ) 
{

    const uart_config_t uart_config = {
        .baud_rate = cfg->baud_rate,
        .data_bits = cfg->data_bit,
        .parity = cfg->parity_bit,
        .stop_bits = cfg->stop_bit,
        .flow_ctrl = UART_HW_FLOWCTRL_DISABLE,
        .source_clk = UART_SCLK_DEFAULT,
    };
    // We won't use a buffer for sending data.
    uart_driver_install(UART_NUM_1, sizeof(ctx->uart_rx_buffer) * 2, 0, 0, NULL, 0);
    uart_param_config(UART_NUM_1, &uart_config);
    uart_set_pin(UART_NUM_1, cfg->tx_pin, cfg->rx_pin, UART_PIN_NO_CHANGE, UART_PIN_NO_CHANGE);


    // Output pins
    //TODO digital_out_init( &ctx->rst, cfg->rst );

    // Dummy read to enable RX interrupt
    //uint8_t dummy_read = 0;
    //uart_read ( &ctx->uart, &dummy_read, 1 );

    return 0;
}

err_t lr14_generic_write ( lr14_t *ctx, uint8_t *data_in, uint16_t len ) 
{
    return uart_write( &ctx->uart, data_in, len );
}

err_t lr14_generic_read ( lr14_t *ctx, uint8_t *data_out, uint16_t len ) 
{
    return uart_read( &ctx->uart, data_out, len );
}

void lr14_set_rst_pin ( lr14_t *ctx, uint8_t state )
{
    //TODO digital_out_write ( &ctx->rst, state );
}

void lr14_reset_device ( lr14_t *ctx )
{
    //TODO digital_out_low ( &ctx->rst );
    Delay_100ms ( );
    //TODO digital_out_high ( &ctx->rst );
    Delay_1sec ( );
    Delay_1sec ( );
    Delay_1sec ( );
}

void lr14_cmd_run ( lr14_t *ctx, uint8_t *cmd )
{
    uint8_t cr_lf[ 3 ] = { '\r', '\n', 0 };
    strcpy( ctx->cmd_buffer, cmd );
    strcat( ctx->cmd_buffer, cr_lf );
    lr14_generic_write( ctx, ctx->cmd_buffer, strlen ( ctx->cmd_buffer ) );
    Delay_100ms(  );
}

void lr14_cmd_set ( lr14_t *ctx, uint8_t *cmd, uint8_t *value )
{
    uint8_t equal_char[ 2 ] = { '=', 0 };
    strcpy( ctx->cmd_buffer, cmd );
    strcat( ctx->cmd_buffer, equal_char );
    strcat( ctx->cmd_buffer, value );
    lr14_cmd_run( ctx, ctx->cmd_buffer );
}

void lr14_cmd_get ( lr14_t *ctx, uint8_t *cmd )
{
    uint8_t check_char[ 2 ] = { '?', 0 };
    lr14_cmd_set( ctx, cmd, check_char );
}

void lr14_cmd_help ( lr14_t *ctx, uint8_t *cmd )
{
    uint8_t check_char[ 2 ] = { '?', 0 };
    strcpy( ctx->cmd_buffer, cmd );
    strcat( ctx->cmd_buffer, check_char );
    lr14_cmd_run( ctx, ctx->cmd_buffer );
}

// ------------------------------------------------------------------------- END
