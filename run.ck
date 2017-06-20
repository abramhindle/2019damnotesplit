SndBuf chirpy => dac;
SndBuf listening => dac;
SndBuf completed => dac;
SndBuf countering => dac;
"chirpy.wav" => chirpy.read;
"listening.44.wav" => listening.read;
"completed.44.wav" => completed.read;
"countering.44.wav" => countering.read;
chirpy.play(0);
listening.play(0);
completed.play(0);
countering.play(0);

MidiOut mout;
mout.open(0);
MidiMsg msg;

function void playNote(int channel, int note, int velocity, dur duration) {
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

function void playBuf(SndBuf sndBuf) {
  0 => sndBuf.pos;
  sndBuf.play(1);
  sndBuf.samples() :: samp => now;
}

function void playBufPrefix(SndBuf chirpy, SndBuf sndBuf) {
  playBuf(chirpy);
  playBuf(sndBuf);
}

// adc
SndBuf fake => LiSa loop1 => HPF hp => Gain g => dac;
fake => LiSa chorusLoop => hp;
fake => LiSa granularLoop => hp;
fake => LiSa loop2 => hp;
fake => LiSa loop3 => hp;
fake => LiSa loop4 => hp;
fake => LiSa loop5 => hp;
fake => LiSa loop6 => hp;


20.0 => hp.freq;
1.0 => hp.Q;
fake => Gain g2 => dac;
30::second => dur mydur;
0.95 => float recordingVolume;
1.0 => g.gain;
0.0 => g2.gain;
mydur => loop.duration;
mydur => chorusLoop.duration;
mydur => granularLoop.duration;

"Sample_1.wav" => fake.read;
// "Sample_2.wav" => fake.read;
// "Sample_3.wav" => fake.read;
// "Sample_4.wav" => fake.read;
// "Sample_5.wav" => fake.read;
// "aria_da_capo.wav" => fake.read; // good example of not handling low volume
fake.play(1);
200 => loop.maxVoices;
200 => chorusLoop.maxVoices;
200 => granularLoop.maxVoices;

function void recording(LiSa loop, dur mydur) {
  <<< "listening" >>>;
  playBuf(chirpy);
  playBufPrefix(chirpy,listening);
  recordingVolume => g2.gain;
  100::ms => now;
  loop.recPos(0::ms);
  loop.record(1);
  mydur => now;
  loop.record(0);
  loop.playPos(0::ms);
  0.0 => g2.gain;
}

function void testPlay() {
  playBuf(chirpy);
  playBufPrefix(chirpy,listening);
  playBufPrefix(chirpy,countering);
  playBufPrefix(chirpy,completed);
}      

function void counter() {
  <<< "Countering" >>>;
  playBuf(chirpy);
  playBuf(chirpy);
  playBufPrefix(chirpy,countering);
}

playBuf(chirpy);
playBuf(chirpy);
playBuf(chirpy);

recording(chorusLoop,mydur);
counter();
chorus(chorusLoop,mydur);

recording(granularLoop,mydur);
counter();
granular(granularLoop,mydur);

recording(loop,mydur);
counter();
sineVocoder(loop,mydur);

recording(loop,mydur);
counter();
adsrSqrVocoder(loop,mydur);

recording(loop,mydur);
counter();
midiVocoder(loop,mydur,0);

recording(loop,mydur);
counter();
midiVocoder(loop,mydur,1);

playBufPrefix(chirpy,completed);


function void playItAllSimple() {
// Good for debugging
  recording(chorusLoop,mydur);
  chorus(chorusLoop,mydur);
  recording(granularLoop,mydur);
  granular(granularLoop,mydur);
  recording(loop,mydur);
  sineVocoder(loop,mydur);
  adsrSqrVocoder(loop,mydur);
  midiVocoder(loop,mydur,0);
  midiVocoder(loop,mydur,1);
}



fun void adsrSqrVocoder(LiSa loop, dur duration) {
  <<< "ADSR Square Vocoder" >>>;
  loop.getVoice() => int newvoice;
  loop.playPos(newvoice, 0::ms);
  loop.rate(newvoice, 1);
  loop.play(newvoice, 1);
  0.0 => g.gain;
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
  0.01 => float threshold;
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
  loop.rampDown(newvoice,200::ms);
  for( 1 => int i; i < 100 ; i++ ) {
    for( 0 => int j; j < n ; j++ ) {
      gains[j] / (i*i) => sines[j].gain;
    }
    10::ms => now;
  }
  for( 0 => int j; j < n ; j++ ) {
    0.0 => sines[j].gain;
  }
  1.0 => g.gain;
}   

fun void chorus(LiSa loop, dur duration) {
  <<< "chorus" >>>;
  1.0 => g.gain;
  8 => int n;
  int voices[8];
  for( 0 => int i; i < n ; i++ ) {
    loop.getVoice() => int newvoice;
    newvoice => voices[i];
    loop.playPos(newvoice, 0::ms);
    loop.play(newvoice,1);
    loop.loop(newvoice,1);
    if (i % 2 == 1) {
      loop.rate(newvoice,0.1 + (i*0.8/n));
    } else {
      loop.rate(newvoice,1.5 + (i*5.0/n));
    }
    loop.voiceGain(newvoice,1.0/n);
  }               
  duration => now;
  for( 0 => int i; i < n ; i++ ) {
    loop.rampDown(voices[i], 100::ms);
  }
  100::ms => now;
}



// Stolen From http://wiki.cs.princeton.edu/index.php/LiSa_munger1.ck  Dan Trueman, 2007
fun void getgrain(LiSa loop, dur grainlen, dur rampup, dur rampdown, float rate)
{
  loop.getVoice() => int newvoice;
  //<<<newvoice>>>;

  if(newvoice > -1) {
    loop.loop(newvoice, 1);
    loop.rate(newvoice, rate);
    loop.voiceGain(newvoice,0.05);
    loop.playPos(newvoice, Std.rand2f(0., 15000.) * 1::ms);
    //loop.playPos(newvoice, 20::ms);
    //<<<l.playpos(newvoice)>>>;
    loop.rampUp(newvoice, rampup);
    (grainlen - (rampup + rampdown)) => now;
    loop.rampDown(newvoice, rampdown);
    rampdown => now;
  }
  
}

// Stolen From http://wiki.cs.princeton.edu/index.php/LiSa_munger1.ck  Dan Trueman, 2007
fun void granular(LiSa loop, dur duration) {
  <<< "granular" >>>;
  1.0 => g.gain;
  now + duration => time toolate;
  
  while (now < toolate) {
    
    Std.rand2f(0.2, 20.0) => float newrate;
    Std.rand2f(250, 750) * 1::ms => dur newdur;
    
    spork ~ getgrain(loop, newdur, 20::ms, 20::ms, newrate);
 
    10::ms => now;
  }         
  
};

fun void sineVocoder(LiSa loop, dur duration) {
  <<< "Sine Vocoder" >>>;
  loop.getVoice() => int newvoice;
  loop.rate(newvoice, 1);
  loop.play(newvoice, 1);
  loop.playPos(newvoice, 0::ms);

  256 => int window_size;
  8 => int n;
  0.0 => g.gain;
  float gains[n];
  BPF bpfs[n];
  BPF bpfs2[n];
  FFT ffts[n];
  RMS rmss[n];
  SinOsc sines[n];
  0.9 => float mix;
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
    sines[i] => bpfs2[i] => dac;
    // left here
  }
  while (now < end) {
    for( 0 => int i; i < n ; i++ ) {
      rmss[i].upchuck();
      rmss[i].fval(0) => float v;
      //<<< v >>>;
      if (v > threshold) {
        (1.0-mix)*(16.0/i)*10*v + mix*gains[i] => gains[i];
      } else {                
        mix*gains[i] => gains[i];
      }
      gains[i] => sines[i].gain;
      
    }
    // set window (optional here)
    window_size::samp => now;
  }
  <<< "release" >>>;
  loop.rampDown(newvoice, 100::ms);

  for( 1 => int i; i < 100 ; i++ ) {
    for( 0 => int j; j < n ; j++ ) {
      gains[j] / (i*i) => sines[j].gain;
    }
    20::ms => now;
  }
  for( 0 => int j; j < n ; j++ ) {
    0 => sines[j].gain;
  }
  1.0 => g.gain;
}   

fun void midiVocoder(LiSa loop, dur duration, int channel) {
  <<< "Midi Square Vocoder" >>>;
  loop.getVoice() => int newvoice;
  loop.rate(newvoice, 1);
  loop.play(newvoice, 1);
  loop.playPos(newvoice, 0::ms);

  0.0 => g.gain;
  256 => int window_size;
  8 => int n;
  float gains[n];
  BPF bpfs[n];
  FFT ffts[n];
  RMS rmss[n];
  0.8 => float mix;
  0.01 => float threshold;
  duration + now => time end;
  //  G, A, B♭, C, D, E♭, and F. and G
  [5, 19, 33, 46, 60, 74, 87, 101, 115] @=> int midis[];
  for( 0 => int i; i < n ; i++ ) {
    loop => bpfs[i];
    bpfs[i] => ffts[i];
    ffts[i] =^ rmss[i];
    rmss[i] => blackhole;
    float gains[i];
    1.0 => bpfs[i].Q;
    Std.mtof(midis[i]) => bpfs[i].freq;        
    window_size => ffts[i].size;
    Windowing.hann( window_size ) => ffts[i].window;
  }
  while (now < end) {
    for( 0 => int i; i < n ; i++ ) {
      rmss[i].upchuck();
      rmss[i].fval(0) => float v;
      if (v > threshold) {
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
