# BEAMS At the 2019 WORKS Feedback Fedback Performance

run-refactored.ck contains a program that listens and responds to music on its own.

# generate album art?

Try our python notebook: https://github.com/abramhindle/2019damnotesplit/blob/master/DamNoTe%20Split.ipynb

# To regenerate the album try to run:

Run: 

    for file in DT_AbramSample1.wav DT_AbramSample2.wav DT_AbramSample3.wav DT_AbramSample4.wav DT_AbramSample5.wav DT_AbramSample6.wav
    do
        bash auto-demo2.sh $file
    done

Use `jack_capture` to record it.

# File descriptions

* adsr-vocode.ck adsr vocoding
* better-midi-vocoder.ck a better midi vocoder
* midi.ck midi test
* midi-crash.ck example of how to crash chuck if you aren't running the dev version
* midi-vocode.ck a midi vocoder
* playit.sh plays sample music into chuck
* playsample.sh plays sample music into chuck
* record.ck demonstrates recording
* run.ck initial demo
* run-refactored.ck final performance
