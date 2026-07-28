#!/bin/bash

kpackagetool6 -t Plasma/Applet -r com.bumderland.quicklaunch
kpackagetool6 -t Plasma/Applet -i com.bumderland.quicklaunch
plasmashell --replace &
