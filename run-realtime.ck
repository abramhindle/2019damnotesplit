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
adc => LiSa loop => HPF hp => Gain g => dac;
adc => LiSa chorusLoop => hp;
adc => LiSa granularLoop => hp;
adc => Gain g2 => dac;
// SndBuf fake => LiSa loop => HPF hp => Gain g => dac;
// fake => LiSa chorusLoop => hp;
// fake => LiSa granularLoop => hp;
// fake => Gain g2 => dac;
// fake => LiSa loop2 => hp;
// fake => LiSa loop3 => hp;
// fake => LiSa loop4 => hp;
// fake => LiSa loop5 => hp;
// fake => LiSa loop6 => hp;


20.0 => hp.freq;
1.0 => hp.Q;
120::second => dur mydur;
0.95 => float recordingVolume;
1.0 => g.gain;
0.0 => g2.gain;
mydur => loop.duration;
mydur => chorusLoop.duration;
mydur => granularLoop.duration;

// "Sample_1.wav" => fake.read;
//"aria_da_capo.wav" => fake.read; // good example of not handling low volume

// "aria_da_capo_loud.wav" => fake.read;
// fake.play(1);
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

/*
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
*/




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



class AbsVocoder {
    float gains[];
    // template method
    fun string name() {
        return "ABS Vocoder";
    }
    fun void vocoder(UGen loop, dur duration) {
        <<< name() >>>;
        0.0 => g.gain;
        //loop.getVoice() => int newvoice;
        //loop.rate(newvoice, 1);
        //loop.play(newvoice, 1);
        //loop.playPos(newvoice, 0::ms);
        // 0.0 => g.gain; // remember to mute!
        windowSize() => int window_size;
        getN() => int n;
        float gains[n];
        
        BPF bpfs[n];
        FFT ffts[n];
        RMS rmss[n];
        mix() => float mix;  
        duration + now => time end;
        threshold() => float threshold;
    
        for( 0 => int i; i < n ; i++ ) {
            loop => bpfs[i];
            bpfs[i] => ffts[i];
            ffts[i] =^ rmss[i];
            rmss[i] => blackhole;
            1.0 => bpfs[i].Q;
            freq(i) => bpfs[i].freq;        
            window_size => ffts[i].size;
            Windowing.hann( window_size ) => ffts[i].window;
        }
        setupVocoder();
        while (now < end) {
            float oldgain;
            for( 0 => int i; i < n ; i++ ) {
                rmss[i].upchuck();
                rmss[i].fval(0) => float v;
                gains[i] => oldgain;
                gains[i]*mix + (1.0 - mix)*v => gains[i];
                if (v > 0 && v > threshold * oldgain) {       
                    playANote(i,v,gains[i]);
                } else {
                    stopANote(i,v,gains[i]);
                }
            }
            window_size::samp => now;
        }
        <<< "release" >>>;
        //loop.play(newvoice,0);
        turnOff();
        1::second => now;        
    }        
    // abstractish methods
    fun void setupVocoder() {
        // setup
    }
    fun void playANote(int i, float rms, float gain) {
        // play a note 
    }
    fun void stopANote(int i, float rms, float gain) {
        // stop it
    }
    fun void turnOff() {
        // turn notes off
        // for( 0 => int i; i < n ; i++ ) {
        //     for( 0 => int j; j < n ; j++ ) {
        //         spork ~ noteOff(channels[i], midis[i], velocities[j]);
        //     }
        // }
    }
    fun int getN() {
        return 8;
    }
    // you can override these
    fun int windowSize() {
        return 256;
    }
    fun float mix() {
        return 0.99;
    }
    1.1 => float _threshold;
    fun float threshold() {
        return _threshold;
    }
    fun int midi(int i) {
        return 0;
    }
    fun float freq(int i) {
        return Std.mtof(midi(i));
    }
}
[5, 19, 33, 46, 60, 74, 87, 101, 115] @=> int favMidis[];

class SineVocoder extends AbsVocoder {
    fun string name() {
        return "Sine Vocoder";
    }
    fun int getN() {
        return 8;
    }
    float sgains[];
    SinOsc sines[];

    fun void setupVocoder() {
        getN() => int n;
        float _gains[n];
        SinOsc _sines[n];
        _sines @=> sines;
        _gains @=> sgains;
        BPF bpfs2[n];
        for( 0 => int i; i < n ; i++ ) {
            0.6 => bpfs2[i].Q;
            freq(i) => bpfs2[i].freq;        
            0.01 => sines[i].gain;
            freq(i) => sines[i].freq;
            sines[i] => bpfs2[i] => dac;
        }
    }
    fun int midi(int i) {
        return favMidis[i];
    }
    fun void playANote(int i, float rms, float gain) {
        // play a note
        mix() => float mix;
        (1.0-mix)*(16.0/i)*10*rms + mix*sgains[i] => sgains[i];
        sgains[i] => sines[i].gain;       
    }
    fun void stopANote(int i, float rms, float gain) {
        mix()*sgains[i] => sgains[i];
        sgains[i] => sines[i].gain;
    }
    fun void turnOff() {
        getN() => int n;
        for( 1 => int i; i < 100 ; i++ ) {
            for( 0 => int j; j < n ; j++ ) {
                sgains[j] / (i*i) => sines[j].gain;
            }
            20::ms => now;
        }
        for( 0 => int j; j < n ; j++ ) {
            0 => sines[j].gain;
        }
    }
}


class AdsrSqrVocoder extends SineVocoder {
    ADSR envs[];
    fun string name() { return "ADSR Sine Vocoder"; }
    fun void setupVocoder() {
        getN() => int n;
        float _gains[n];
        SinOsc _sines[n];
        ADSR _envs[n];
        _sines @=> sines;
        _gains @=> sgains;
        _envs  @=> envs;
        BPF bpfs2[n];
        for( 0 => int i; i < n ; i++ ) {
            0.6 => bpfs2[i].Q;
            freq(i) => bpfs2[i].freq;        
            0.01 => sines[i].gain;
            freq(i) => sines[i].freq;
            sines[i] => bpfs2[i] => envs[i] => dac;
            windowSize()::samp =>  envs[i].attackTime;
            windowSize()::samp =>  envs[i].decayTime;
            0.5 => envs[i].sustainLevel;
            0.5::second =>  envs[i].releaseTime;
        }
    }

    fun void playANote(int i, float rms, float gain) {
        // play a note
        mix() => float mix;
        (1.0-mix)*(16.0/i)*10*rms + mix*sgains[i] => sgains[i];
        sgains[i] => sines[i].gain;
        envs[i].keyOn();
    }
    fun void stopANote(int i, float rms, float gain) {
        mix()*sgains[i] => sgains[i];
        sgains[i] => sines[i].gain;
        envs[i].keyOff();
    }
}   


class MidiVocoder extends AbsVocoder {
    fun string name() {
        return "Midi Vocoder";
    }
    fun int midi(int i) {
        return favMidis[i];
    }
    // set these your selves?
    [5, 19, 33, 46, 60, 74, 87, 101, 115] @=> int midis[];
    [0,1,2,3,4,5,6,7,8,9] @=> int channels[];
    //[0,0,8,8,8,5,6,7,9,9] @=> int channels[];
    //[0,15,0,15,0,15,0,15,0] @=> int channels[];
    [1::second,0.5::second,0.25::second,100::ms,100::ms,100::ms,50::ms,50::ms,50::ms,50::ms] @=> dur durs[];
    [127,127,90,90,80,80,64,64,64,64,64,64] @=> int velocities[];   
    fun void playANote(int i, float rms, float gain) {
        // play a note
        spork ~ playNote(channels[i], midis[i], velocities[i], durs[i]);
    }
    fun void stopANote(int i, float rms, float gain) {
        "do nothing";
    }
    fun void turnOff() {
        getN() => int n;
        for( 0 => int i; i < n ; i++ ) {
            for( 0 => int j; j < n ; j++ ) {
                spork ~ noteOff(channels[i], midis[i], velocities[j]);
            }
        }
    }
}

//[5, 19, 33, 46, 60, 74, 87, 101, 115] @=> int favMidis[];

class PinkVocoder extends AbsVocoder {
    fun string name() {
        return "Pink Vocoder";
    }
    fun int getN() {
        return 8;
    }
    float sgains[];
    Gain ngains[];
    Noise noise;

    fun void setupVocoder() {
        //noise.mode("pink");
        getN() => int n;
        float _sgains[n];
        Gain _ngains[n];
        Noise _noise => 
        _ngains @=> ngains;
        _sgains @=> sgains;
        BPF bpfs2[n];
        for( 0 => int i; i < n ; i++ ) {
            4.00 => bpfs2[i].Q;
            freq(i) => bpfs2[i].freq;        
            0.01 => ngains[i].gain;
            noise => ngains[i] => bpfs2[i] => dac;
        }
    }
    fun int midi(int i) {
        return 12 * (i + 1);
    }
    fun void playANote(int i, float rms, float gain) {
        // play a note
        mix() => float mix;
        (1.0-mix)*(16.0/i)*10*rms + mix*sgains[i] => sgains[i];
        sgains[i] => ngains[i].gain;       
    }
    fun void stopANote(int i, float rms, float gain) {
        mix()*sgains[i] => sgains[i];
        sgains[i] => ngains[i].gain;
    }
    fun float mix() { return 0.1; }
    fun void turnOff() {
        getN() => int n;
        for( 1 => int i; i < 100 ; i++ ) {
            for( 0 => int j; j < n ; j++ ) {
                sgains[j] / (i*i) => ngains[j].gain;
            }
            20::ms => now;
        }
        for( 0 => int j; j < n ; j++ ) {
            0 => ngains[j].gain;
        }
    }
}



function void main() {


   playBuf(chirpy);
   playBuf(chirpy);
   playBuf(chirpy);
   
   recording(chorusLoop,mydur);
   counter();
   chorus(chorusLoop,mydur);
   
   recording(granularLoop,mydur);
   counter();
   granular(granularLoop,mydur);
   
   //recording(loop,mydur);
   //counter();
   ////sineVocoder(loop,mydur);
   //SineVocoder sineVocoder;
   //sineVocoder.vocoder(loop,mydur);
   //
   
   recording(loop,mydur);
   counter();
   AdsrSqrVocoder adsrSqrVocoder;
   adsrSqrVocoder.vocoder(loop,mydur);
   
   
   recording(loop,mydur);
   counter();
   MidiVocoder midiVocoder;
   [0,0,0,0,0,0,0,0,0] @=> midiVocoder.channels;
   midiVocoder.vocoder(loop,mydur);
   
   
   recording(loop,mydur);
   counter();
   MidiVocoder midiVocoder2;
   2.0 => midiVocoder2._threshold;
   [0,1,2,3,4,5,6,7,8,9] @=> midiVocoder2.channels;
   midiVocoder2.vocoder(loop,mydur);
   
   
   
   recording(loop,mydur);
   counter();
   MidiVocoder midiVocoder3;
   2.0 => midiVocoder3._threshold;
   [15,15,8,8,8,5,6,7,9,9] @=> midiVocoder3.channels;
   [1::second,0.5::second,0.25::second,100::ms,100::ms,100::ms,50::ms,50::ms,50::ms,50::ms] @=> midiVocoder3.durs;
   [127,127,90,90,80,80,64,64,64,64,64,64] @=> midiVocoder3.velocities;
   midiVocoder3.vocoder(loop,mydur);
   
   playBufPrefix(chirpy,completed);
}

//AdsrSqrVocoder adsrSqrVocoder;
//adsrSqrVocoder.vocoder(adc,mydur);

MidiVocoder midiVocoder3;
Std.rand2f(1.0,3.0) => midiVocoder3._threshold;
[33, 35, 37, 39, 41, 43, 45, 47, 49] @=> midiVocoder3.midis;
20 => int mlow;
40 => int mhigh;
[Std.rand2(mlow,mhigh),Std.rand2(mlow,mhigh),Std.rand2(mlow,mhigh),Std.rand2(mlow,mhigh),Std.rand2(mlow,mhigh),
 Std.rand2(mlow,mhigh),Std.rand2(mlow,mhigh),Std.rand2(mlow,mhigh),Std.rand2(mlow,mhigh),Std.rand2(mlow,mhigh)] @=> midiVocoder3.midis;

[15,15,8,8,8,5,6,7,9,9] @=> midiVocoder3.channels;
[1,2,3,4,5,6,7,8,9,10] @=> midiVocoder3.channels;
[Std.rand2(1,16),Std.rand2(1,16),Std.rand2(1,16),Std.rand2(1,16),Std.rand2(1,16),
Std.rand2(1,16),Std.rand2(1,16),Std.rand2(1,16),Std.rand2(1,16),Std.rand2(1,16)] @=> midiVocoder3.channels;
500 => int low;
2000 => int high;
[Std.rand2(low,high)::ms,Std.rand2(low,high)::ms,Std.rand2(low,high)::ms,Std.rand2(low,high)::ms,Std.rand2(low,high)::ms,
 Std.rand2(low,high)::ms,Std.rand2(low,high)::ms,Std.rand2(low,high)::ms,Std.rand2(low,high)::ms,Std.rand2(low,high)::ms] @=> midiVocoder3.durs;
//favMidis @=> midiVocoder3.channels;
//[1::second,0.5::second,0.25::second,100::ms,100::ms,100::ms,50::ms,50::ms,50::ms,50::ms] @=> midiVocoder3.durs;
//[1::second,1::second,1::second,1::second,1::second,
// 1::second,1::second,1::second,1::second,1::second] @=> midiVocoder3.durs;
// .5::second,0.25::second,100::ms,100::ms,100::ms,50::ms,50::ms,50::ms,50::ms] @=> midiVocoder3.durs;

[Std.rand2(20,120),Std.rand2(20,120),Std.rand2(20,120),Std.rand2(20,120),Std.rand2(20,120),
 Std.rand2(20,120),Std.rand2(20,120),Std.rand2(20,120),Std.rand2(20,120),Std.rand2(20,120)] @=> midiVocoder3.velocities;
//[127,127,90,90,80,80,64,64,64,64,64,64] @=> midiVocoder3.velocities;
//midiVocoder3.vocoder(adc,mydur);

PinkVocoder pink;
pink.vocoder(adc, mydur);
