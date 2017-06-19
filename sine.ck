SinOsc s => Gain g => dac;
440.0 => s.freq;
1.0 => g.gain;
10::second => now;
