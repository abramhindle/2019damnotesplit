import rtmidi
import liblo
import time

server = liblo.Server(10001)
midiout = rtmidi.MidiOut()
midiout.open_virtual_port("My virtual output")

class Notes:
    def __init__(self):
        self.notes = []
    def add_note(self, note, c=0x0):
        self.notes.append((note,c,time.time()))
    def get_notes(self):
        return self.notes
    def del_note(self, note, c=0x0):
        out = list()
        for x in self.notes:
            (note1,c1,time1) = x
            if not (note1 == note and c == c1):
                out.append(x)
        self.notes = out

my_notes = Notes()

def conv_note(i):
    return int(i)

def noteon(note,channel=0x0):
    note_on = [0x90 | channel, int(note), 60 ] 
    midiout.send_message( note_on )

def noteon_cb(path, args):
    i = args[0]
    note = conv_note(i)
    noteon(note,0)
    my_notes.add_note(note)

def noteonc_cb(path, args):
    i = args[0]
    c = args[1]
    print(i,c)
    note = conv_note(i)
    noteon(note,c)
    my_notes.add_note(note,c)

def noteoff(note,channel=0x0):
    note_off = [0x80 | channel, int(note), 0 ] 
    midiout.send_message( note_off )

def noteoff_cb(path, args):
    i = args[0]
    note = conv_note(i)
    noteoff(note)
    my_notes.del_note(note)

def noteoffc_cb(path, args):
    i = args[0]
    c = args[1]
    note = conv_note(i)
    noteoff(note,c)
    my_notes.del_note(note,c)

server.add_method("/noteon", 'i', noteon_cb)
server.add_method("/noteoff", 'i', noteoff_cb)
server.add_method("/noteonc", 'ii', noteonc_cb)
server.add_method("/noteoffc", 'ii', noteoffc_cb)

while True:
    server.recv(100)
    now = time.time()
    for note in my_notes.get_notes():
        n,c,t = note
        if now - t > 10.0:
            print "Deleting old note: (%s,%s,%s)" % note
            noteoff(n,c)
            my_notes.del_note(n,c)
