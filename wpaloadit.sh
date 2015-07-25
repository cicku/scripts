#!/bin/sh
if [ ! "$1" ]; then
{
  echo "Usage: wpaloadit [WPA_SUPPLICANT.CONF]"
  exit 1
}
  else
{
  echo -en "Loading wlan0... "
  sudo ifconfig wlan0 up
  echo "done."
  sleep 1
  echo -en "Loading wpa_supplicant configuration... "
  #sudo iwconfig wlan0 power on
  #sleep 1
  sudo wpa_supplicant -qq -c "$1" -i wlan0 &
  sleep 5
  echo "done."
  echo -en "Requesting IP from AP:\n"
  sudo dhcpcd wlan0
  #sudo dhclient wlan0

}
fi
