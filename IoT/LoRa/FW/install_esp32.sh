#!/bin/bash


code --install-extension espressif.esp-idf-extension

# Install from GUI:
# https://www.waveshare.com/wiki/ESP32-C6-Pico#Install_Espressif_IDF_Plug-in

sudo cp --update=none /home/micuri/.local/opt/.espressif/tools/openocd-esp32/v0.12.0-esp32-20241016/openocd-esp32/share/openocd/contrib/60-openocd.rules /etc/udev/rules.d