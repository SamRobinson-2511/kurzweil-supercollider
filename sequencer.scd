(
MIDIClient.init;
MIDIClient.destinations;
m = MIDIOut(3);
m.latency = 0;
)

m.noteOn(0, 60, 127);
Scale.directory;
(
~midiPattern = Pbind(
	\type, \midi,
	\midicmd, \noteOn,
	\midiout, m,
	\chan, 0,
	\scale, Scale.yu,
	\degree, Pseq([0, 2, 4], inf),
	\octave, 4,
	\dur, 0.25,
	\legato, 0.5
)
)
~midiPattern.play;
~midiPattern.stop;

