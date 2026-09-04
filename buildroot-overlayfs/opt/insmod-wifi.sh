#!/bin/sh

insmod /usr/ko/ecc.ko
insmod /usr/ko/libarc4.ko
insmod /usr/ko/libaes.ko
insmod /usr/ko/arc4.ko
insmod /usr/ko/aes_generic.ko
insmod /usr/ko/ecdh_generic.ko
insmod /usr/ko/cfg80211.ko
insmod /usr/ko/mac80211.ko
insmod /usr/ko/bluetooth.ko
insmod /usr/ko/esp32_spi.ko resetpin=2 clockspeed=26

