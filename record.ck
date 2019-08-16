adc => LiSa loop => Gain g => dac;
adc => Gain g2 => dac;
0.0 => g.gain;
2::second => loop.duration;
loop.record(1);
<<< "5 seconds" >>>;
2::second => now;
<<< "Done Recording" >>>;
loop.record(0);
1.0 => g.gain;
0 => g2.gain;
loop.getVoice() => int voice1;
loop.play(voice1,1);
loop.loop(voice1,1);
loop.rate(voice1,-0.5);

<<< "Now 10 seconds" >>>;
10::second => now;
loop.rampDown(voice1, 100::ms);
<<< "Now for granular synthesis" >>>;
granular(10::second);
//10::second => now;
<<< "Now for chorus" >>>;
chorus(loop,10::second);
//10::second => now;

fun void chorus(LiSa loop, dur duration) {
    8 => int n;
    int voices[8];
    for( 0 => int i; i < n ; i++ ) {
    	 loop.getVoice() => int newvoice;
         newvoice => voices[i];
         loop.play(newvoice,1);
         loop.loop(newvoice,1);
         loop.rate(newvoice,1.0 + 0.3*(i - n/2)/(n/2.0));
    }               
    duration => now;
    for( 0 => int i; i < n ; i++ ) {
         loop.rampDown(voices[i], 100::ms);
    }
    100::ms => now;
}


// Stolen From http://wiki.cs.princeton.edu/index.php/LiSa_munger1.ck  Dan Trueman, 2007
fun void granular(dur duration) {
    now + duration => time toolate;

    while (now < toolate) {
          
	 Std.rand2f(1.5, 2.0) => float newrate;
	 Std.rand2f(250, 750) * 1::ms => dur newdur;
 
 	 spork ~ getgrain(newdur, 20::ms, 20::ms, newrate);
 
	 10::ms => now;
    }         
 
};


fun void getgrain(dur grainlen, dur rampup, dur rampdown, float rate)
{
	 loop.getVoice() => int newvoice;
	 //<<<newvoice>>>;
	 
	 if(newvoice > -1) {
		 loop.rate(newvoice, rate);
                 loop.playPos(newvoice, Std.rand2f(0., 2000.) * 1::ms);
		 //loop.playPos(newvoice, 20::ms);
		 //<<<l.playpos(newvoice)>>>;
		 loop.rampUp(newvoice, rampup);
		 (grainlen - (rampup + rampdown)) => now;
		 loop.rampDown(newvoice, rampdown);
		 rampdown => now;
	 }
 
 }

fun void vocoder(LiSa loop, dur duration) {
	 loop.getVoice() => int newvoice;
         loop.rate(newvoice, 1);
         loop.play(newvoice, 1);
         8 => n;
         BPF bpfs[n];
         FFT ffts[n];
         RMS rmss[n];
         SinOsc sines[n];
         //  G, A, B♭, C, D, E♭, and F. and G
         [19, 33, 46, 60, 74, 87, 101, 115] @=> int midis[];
         for( 0 => int i; i < n ; i++ ) {
              loop => bpfs[i] => FFT ffts[i] ^= rmss[i] => blackhole;
              // left here
         }
         
         
}   
