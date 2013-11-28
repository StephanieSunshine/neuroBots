#!/bin/bash
cd /home/vip/controller
pkill -9 ruby*
sleep 2
./restart-system-from-botlist.rb

