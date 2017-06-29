MidiOut mout;
mout.open(0);
MidiMsg msg;

adc => LiSa loop => dac;
5::second => loop.duration;

// 1.0 => g.gain;
recording(loop, 5::second);
<<< "playing" >>>;
loop.getVoice() => int newvoice;
loop.rate(newvoice, 1);
loop.play(newvoice, 1);
loop.playPos(newvoice, 0::ms);
5::second => now;
loop.playPos(newvoice, 0::ms);
loop.play(newvoice, 0);

midiVocoder(loop, 10::second, 0);
function void playNote(int channel, int note, int velocity, dur duration) {
    <<< (channel, note) >>>;
    noteOn(channel,note,velocity);
    duration => now;
    noteOff(channel,note,velocity);
}

function void noteOn(int channel, int note, int velocity) {
    0x90 + channel => msg.data1;
    note => msg.data2;
    velocity => msg.data3;
    mout.send(msg);
}
function void noteOff(int channel, int note, int velocity) {
    0x80 + channel => msg.data1;
    note => msg.data2;
    velocity => msg.data3;
    mout.send(msg);
}

function void recording(LiSa loop, dur mydur) {
  <<< "listening" >>>;
  //loop.recPos(0::ms);
  loop.record(1);
  mydur => now;
  loop.record(0);
  loop.playPos(0::ms);
}

fun void midiVocoder(LiSa loop, dur duration, int channel) {
  <<< "Midi Square Vocoder" >>>;
  loop.getVoice() => int newvoice;
  loop.rate(newvoice, 1);
  loop.play(newvoice, 1);
  loop.playPos(newvoice, 0::ms);

  //0.0 => g.gain;
  256 => int window_size;
  8 => int n;
  float gains[n];
  BPF bpfs[n];
  FFT ffts[n];
  RMS rmss[n];
  0.99 => float mix;  
  duration + now => time end;
  //  G, A, B♭, C, D, E♭, and F. and G
  [5, 19, 33, 46, 60, 74, 87, 101, 115] @=> int midis[];
  for( 0 => int i; i < n ; i++ ) {
    loop => bpfs[i];
    bpfs[i] => ffts[i];
    ffts[i] =^ rmss[i];
    rmss[i] => blackhole;
    1.0 => bpfs[i].Q;
    Std.mtof(midis[i]) => bpfs[i].freq;        
    window_size => ffts[i].size;
    Windowing.hann( window_size ) => ffts[i].window;
  }
  while (now < end) {
    float oldgain;
    for( 0 => int i; i < n ; i++ ) {
      rmss[i].upchuck();
        rmss[i].fval(0) => float v;
        gains[i] => oldgain;
        gains[i]*mix + (1.0 - mix)*v => gains[i];
      if (v > 0 && v > oldgain) {
        spork ~ playNote(channel, midis[i], 64, 200::ms);
      } else {
        spork ~ noteOff(channel, midis[i], 64);
      }
    }
    window_size::samp => now;
  }
  <<< "release" >>>;
  loop.play(newvoice,0);
}   
