#!/bin/sh
sudo echo OK
echo "KILLING"
bash kill.sh
sleep 3
echo "JACK CTL"
qjackctl -s &
sleep 3
echo "MIXER"
echo "SETTING VOLUME OFF"
amixer set 'Headphone' Playback 0
amixer set 'Headphone' Playback on
amixer set 'Master' Playback on
amixer set 'Master' Playback 0
pushd ~/projects/mixer/
popd
sleep 5
echo "SETTING VOLUME"
amixer set 'Headphone' Playback 74
amixer set 'Headphone' Playback on
amixer set 'Master' Playback on
amixer set 'Master' Playback 74
qsynth &
sleep 4
# just a guess :/
aconnect 130:0 14:0
aconnect 131:0 14:0
aconnect 132:0 14:0
aconnect 133:0 14:0
aconnect 14:0 130:0
aconnect 14:0 131:0
aconnect 14:0 132:0
aconnect 14:0 133:0
jack_connect  "qsynth:left"  system:playback_1
jack_connect  "qsynth:right" system:playback_2
echo "Press enter to start performance"
read
chuck --srate:48000 run-refactored.ck
