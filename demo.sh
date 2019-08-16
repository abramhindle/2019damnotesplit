# FILES=DT_AbramSample1.wav DT_AbramSample2.wav DT_AbramSample3.wav DT_AbramSample4.wav DT_AbramSample5.wav DT_AbramSample6.wav
FILES=`find dmt2 -iname '*.wav'`
echo PRESS ENTER TO START
read
for file in $FILES
do
	echo $file
	mplayer -ao jack:port=inport -endpos 30 $file
	echo sleep 31
	sleep 31
done

