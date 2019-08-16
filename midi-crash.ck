// Problem, creating MidiOut multiple times crashes chuck on Ubuntu 16.04 64bit x86
// both Jack and PulseAudio and i7 and Xenon.
//
// Suggested places to look
// * MidiOutManager::open -- it makes an RtMidiOut
// * MidiOut constructor -- it makes an RtMidiOut
// * MidiOut.close -- it doesn't close the RtMidiOut (and maybe it shouldn't but shouldn't it tell the RtMidiOut
// 
//
// You should see 3 "Ending" followed by segmentation fault instead of 4
// 
// hindle1@st-francis:~/projects/BEAMS-2017-WORKS$ chuck midi-crash.ck
// "Ending" : (string)
// "Ending" : (string)
// "Ending" : (string)
// Segmentation fault (core dumped)
// 
// 
// hindle1@st-francis:~/projects/BEAMS-2017-WORKS$ chuck --version
// 
// chuck version: 1.3.5.2 (chimera)
//    linux (pulse) : 64-bit
//    http://chuck.cs.princeton.edu/
//    http://chuck.stanford.edu/
//
// hindle1@st-francis:~/projects/BEAMS-2017-WORKS$ lsb_release -a; uname -a
// No LSB modules are available.
// Distributor ID:	Ubuntu
// Description:	Ubuntu 16.04.2 LTS
// Release:	16.04
// Codename:	xenial
// Linux st-francis 4.4.0-31-generic #50-Ubuntu SMP Wed Jul 13 00:07:12 UTC 2016 x86_64 x86_64 x86_64 GNU/Linux
//
// @piggy:/tmp$ chuck --version
// 
// chuck version: 1.3.5.2 (chimera)
//    linux (jack) : 64-bit
//    http://chuck.cs.princeton.edu/
//    http://chuck.stanford.edu/
// 
// @piggy:/tmp$ lsb_release -a; uname -a
// No LSB modules are available.
// Distributor ID:	Ubuntu
// Description:	Ubuntu 16.04.2 LTS
// Release:	16.04
// Codename:	xenial
// Linux piggy 4.4.0-79-lowlatency #100-Ubuntu SMP PREEMPT Wed May 17 20:56:57 UTC 2017 x86_64 x86_64 x86_64 GNU/Linux
// @piggy:/tmp$ chuck midi-crash.ck 
// "Ending" : (string)
// "Ending" : (string)
// "Ending" : (string)
// Segmentation fault (core dumped)
// 
// hindle1@st-francis:~/projects/BEAMS-2017-WORKS$ gdb chuck
// GNU gdb (Ubuntu 7.11.1-0ubuntu1~16.04) 7.11.1
// Copyright (C) 2016 Free Software Foundation, Inc.
// License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
// This is free software: you are free to change and redistribute it.
// There is NO WARRANTY, to the extent permitted by law.  Type "show copying"
// and "show warranty" for details.
// This GDB was configured as "x86_64-linux-gnu".
// Type "show configuration" for configuration details.
// For bug reporting instructions, please see:
// <http://www.gnu.org/software/gdb/bugs/>.
// Find the GDB manual and other documentation resources online at:
// <http://www.gnu.org/software/gdb/documentation/>.
// For help, type "help".
// Type "apropos word" to search for commands related to "word"...
// Reading symbols from chuck...(no debugging symbols found)...done.
// (gdb) run midi-crash.ck 
// Starting program: /usr/local/bin/chuck midi-crash.ck
// [Thread debugging using libthread_db enabled]
// Using host libthread_db library "/lib/x86_64-linux-gnu/libthread_db.so.1".
// [New Thread 0x7fffef745700 (LWP 15520)]
// [New Thread 0x7fffeef44700 (LWP 15521)]
// [New Thread 0x7fffee743700 (LWP 15522)]
// [New Thread 0x7fffedf42700 (LWP 15523)]
// [New Thread 0x7fffed741700 (LWP 15524)]
// "Ending" : (string)
// "Ending" : (string)
// "Ending" : (string)
// 
// Thread 3 "chuck" received signal SIGSEGV, Segmentation fault.
// [Switching to Thread 0x7fffeef44700 (LWP 15521)]
// 0x0000000000000000 in ?? ()
//
// Now with symbols!
//
//
// hindle1@st-francis:~/projects/BEAMS-2017-WORKS$ gdb chuck
// GNU gdb (Ubuntu 7.11.1-0ubuntu1~16.04) 7.11.1
// Copyright (C) 2016 Free Software Foundation, Inc.
// License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
// This is free software: you are free to change and redistribute it.
// There is NO WARRANTY, to the extent permitted by law.  Type "show copying"
// and "show warranty" for details.
// This GDB was configured as "x86_64-linux-gnu".
// Type "show configuration" for configuration details.
// For bug reporting instructions, please see:
// <http://www.gnu.org/software/gdb/bugs/>.
// Find the GDB manual and other documentation resources online at:
// <http://www.gnu.org/software/gdb/documentation/>.
// For help, type "help".
// Type "apropos word" to search for commands related to "word"...
// Reading symbols from chuck...done.
// (gdb) run midi-crash.ck 
// Starting program: /usr/local/bin/chuck midi-crash.ck
// [Thread debugging using libthread_db enabled]
// Using host libthread_db library "/lib/x86_64-linux-gnu/libthread_db.so.1".
// [New Thread 0x7fffef745700 (LWP 16349)]
// [New Thread 0x7fffeef44700 (LWP 16350)]
// [New Thread 0x7fffee743700 (LWP 16351)]
// [New Thread 0x7fffedf42700 (LWP 16352)]
// [New Thread 0x7fffed741700 (LWP 16353)]
// "Ending" : (string)
// "Ending" : (string)
// "Ending" : (string)
// 
// Thread 3 "chuck" received signal SIGSEGV, Segmentation fault.
// [Switching to Thread 0x7fffeef44700 (LWP 16350)]
// 0x000000000049562b in MidiOut::~MidiOut (this=0x7fffc4015190, 
//     __in_chrg=<optimized out>) at midiio_rtmidi.cpp:81
// 81	    SAFE_DELETE( mout );
// (gdb) bt
// #0  0x000000000049562b in MidiOut::~MidiOut (this=0x7fffc4015190, 
//     __in_chrg=<optimized out>) at midiio_rtmidi.cpp:81
// #1  0x00000000004693a4 in MidiOut_dtor (SELF=0x7fffc40150b0, 
//     SHRED=<optimized out>, API=<optimized out>) at chuck_lang.cpp:3878
// #2  0x000000000045bd89 in Chuck_Object::~Chuck_Object (this=0x7fffc40150b0, 
//     __in_chrg=<optimized out>) at chuck_oo.cpp:322
// #3  0x000000000045be19 in Chuck_Object::~Chuck_Object (this=0x7fffc40150b0, 
//     __in_chrg=<optimized out>) at chuck_oo.cpp:333
// #4  0x000000000041d05c in Chuck_VM_Shred::run (vm=0x87a670, 
//     this=0x7fffc4000e00) at chuck_vm.cpp:1823
// #5  Chuck_VM::compute (this=this@entry=0x87a670) at chuck_vm.cpp:687
// #6  0x000000000041d2fd in Chuck_VM::run (this=0x87a670, num_samps=454, 
//     num_samps@entry=512) at chuck_vm.cpp:744
// #7  0x000000000048e6e9 in Digitalio::cb2 (output_buffer=0x882c20, 
//     input_buffer=0x88b670, buffer_size=<optimized out>, 
//     streamTime=<optimized out>, status=<optimized out>, 
//     user_data=<optimized out>) at digiio_rtaudio.cpp:910
// #8  0x000000000049f13a in RtApiPulse::callbackEvent (this=0x8828c0)
//     at RtAudio/RtAudio.cpp:6678
// #9  pulseaudio_callback (user=0x882b18) at RtAudio/RtAudio.cpp:6605
// #10 0x00007ffff70d26ba in start_thread (arg=0x7fffeef44700)
//     at pthread_create.c:333
// #11 0x00007ffff64943dd in clone ()

function void playNote(int channel, int note, int velocity, dur duration, MidiOut mout) {
    MidiMsg msg;
    noteOn(channel,note,velocity,mout);
    duration => now;
    noteOff(channel,note,velocity,mout);
}
    
function void noteOn(int channel, int note, int velocity,MidiOut mout) {
    MidiMsg msg;
   0x90 + channel => msg.data1;
    note => msg.data2;
    velocity => msg.data3;
    mout.send(msg);
}
function void noteOff(int channel, int note, int velocity,MidiOut mout) {
    MidiMsg msg;
    0x80 + channel => msg.data1;
    note => msg.data2;
    velocity => msg.data3;
    mout.send(msg);
}

function void demonstrateACrash() {
    MidiOut mout;
    mout.open(0);
    0 => int channel;
    1::second + now => time til;
    while (now < til) {
        Std.rand2(100,127) => int note;
        Std.rand2(12,100) => int velocity;
        playNote(channel,note,velocity, Std.rand2f(0.1,0.3)::second,mout);
        Std.rand2f(0.1,0.3)::second => now;
    }
    <<< "Ending" >>>;
    3::second => now;
}

spork ~ demonstrateACrash();
1::second => now;
spork ~ demonstrateACrash();
1::second => now;
spork ~ demonstrateACrash();
10::second => now;
spork ~ demonstrateACrash();
5::second => now;
