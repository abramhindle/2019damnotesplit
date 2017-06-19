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
    ADSR envs[n];
    RMS rmss[n];
    SqrOsc sines[n];
    0.8 => float mix;
    0.001 => float threshold;
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
        0.01 => sines[i].gain;
        Std.mtof(midis[i]) => sines[i].freq;
        sines[i] => bpfs2[i] => envs[i] => dac;
        window_size::samp =>  envs[i].attackTime;
        window_size::samp =>  envs[i].decayTime;
        0.5 => envs[i].sustainLevel;
        0.5::second =>  envs[i].releaseTime;
        
        // left here
    }
    while (now < end) {
        for( 0 => int i; i < n ; i++ ) {
            rmss[i].upchuck();
            rmss[i].fval(0) => float v;
            //<<< v >>>;
            if (v > threshold) {
                (1.0-mix)*(16.0/i)*10*v + mix*gains[i] => gains[i];
                envs[i].keyOn();
            } else {                
                mix*gains[i] => gains[i];
                envs[i].keyOff();

            }
            gains[i] => sines[i].gain;

        }
        // set window (optional here)
        window_size::samp => now;
    }
    <<< "release" >>>;
    for( 1 => int i; i < 100 ; i++ ) {
        for( 0 => int j; j < n ; j++ ) {
            gains[j] / (i*i) => sines[j].gain;
        }
        20::ms => now;
    }
}   
