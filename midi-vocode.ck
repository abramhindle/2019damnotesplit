"localhost" => string hostname;
10001 => int port;
OscSend oscSend;
oscSend.setHost( hostname, port );

/*
MidiOut mout;
mout.open(0);
MidiMsg msg;
*/

function void playNote(int channel, int note, int velocity, dur duration) {
    noteOn(channel,note,velocity);
    duration => now;
    noteOff(channel,note,velocity);
}

function void noteOn(int channel, int note, int velocity) {
    oscSend.startMsg("/noteonc","ii");
    note => oscSend.addInt;
    channel => oscSend.addInt;
    // 0x90 + channel => msg.data1;
    // note => msg.data2;
    // velocity => msg.data3;
    // mout.send(msg);
}
function void noteOff(int channel, int note, int velocity) {
    oscSend.startMsg("/noteoffc","ii");
    note => oscSend.addInt;
    channel => oscSend.addInt;
    // 
    // 0x80 + channel => msg.data1;
    // note => msg.data2;
    // velocity => msg.data3;
    // mout.send(msg);
}

adc => LiSa loop => Gain g => dac;
adc => Gain g2 => dac;
// 0.0 => g.gain;
0.1 => g2.gain;
30::second => dur mydur;


mydur => loop.duration;
loop.record(1);
<<< mydur >>>;
mydur => now;
<<< "Done Recording" >>>;
loop.record(0);
//0.00 => g.gain;
0.00 => g2.gain;
//<<< "Review" >>>;
//loop.getVoice() => int newvoice;
//loop.rate(newvoice, 1);
//loop.play(newvoice, 1);
//mydur => now;
//loop.play(newvoice, 0);
0.0 => g.gain;
<<< "vocode" >>>;
vocoder(loop, mydur);
<<< "done" >>>;

fun void vocoder(LiSa loop, dur duration) {
	loop.getVoice() => int newvoice;
    loop.rate(newvoice, 1);
    loop.play(newvoice, 1);
    256 => int window_size;
    8 => int n;
    float gains[n];
    BPF bpfs[n];
    BPF bpfs2[n];
    FFT ffts[n];
    RMS rmss[n];
    0.8 => float mix;
    0.01 => float threshold; // this needs to be set somehow? (median?)
    duration + now => time end;
    //  G, A, B♭, C, D, E♭, and F. and G
    [5, 19, 33, 46, 60, 74, 87, 101, 115] @=> int midis[];
    // [12, 24, 36, 48, 60, 72, 84, 96  ] @=> int midis[];
    for( 0 => int i; i < n ; i++ ) {
        loop => bpfs[i];
        bpfs[i] => ffts[i];
        // bpfs[i] => dac;
        ffts[i] =^ rmss[i];
        rmss[i] => blackhole;
        float gains[i];
        // bpf
        1.0 => bpfs[i].Q;
        Std.mtof(midis[i]) => bpfs[i].freq;        
        0.6 => bpfs2[i].Q;
        Std.mtof(midis[i]) => bpfs2[i].freq;        
        window_size => ffts[i].size;
        Windowing.hann( window_size ) => ffts[i].window;
        
        // left here
    }
    Std.rand2(0,15) => int channel;
    while (now < end) {
        for( 0 => int i; i < n ; i++ ) {
            rmss[i].upchuck();
            rmss[i].fval(0) => float v;
            //<<< v >>>;
            // invert or not?
            if (v > threshold) {
                noteOn(channel,midis[8-i],64);
            } else {                
                noteOff(channel,midis[8-i],64);
            }
        }
        // set window (optional here)
        window_size::samp => now;
    }
    <<< "release" >>>;
    for (0 => int i ; i < n; i++ ) {
        noteOff(channel,midis[i],64);
    }
    100::ms => now;
}   
