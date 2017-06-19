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

Std.rand2(0,15) => int channel;
//1 => channel;
//[2,3,7,15,11] @=> int channels[];
[2,3,4,6,11,12] @=> int channels[];
channels[Std.rand2(0,channels.cap()-1)] => channel;
<<< channel >>>;
while (true) {
    Std.rand2(100,127) => int note;
    Std.rand2(12,100) => int velocity;
    playNote(channel,note,velocity, Std.rand2f(0.1,0.3)::second);
    Std.rand2f(0.1,0.3)::second => now;
}

//for (0 => int i; i < 128; i++ ){
//    playNote(channel,i,64, 0.02::second);
//}


// Std.rand2(1,15) => int channel;
// Std.rand2(1,90)::second => dur duration;
// now + duration => time then;
// while (now < then) {
//     Std.rand2(1,24) => int note;
//     Std.rand2(12,64) => int velocity;
//     playNote(channel,note,velocity,Std.rand2f(0.1,3.2)::second);
//     Std.rand2f(0.1,2.2)::second => now;
// }
// 
//<<< "Ending" >>>;
//:second => now;
