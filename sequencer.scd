(
MIDIClient.init;
MIDIClient.destinations;
m = MIDIOut(2);
m.latency = 0;
)


(
~midiPattern = Pbind(
	\type, \midi,
	\midicmd, \noteOn,
	\midiout, m,
	\chan, 0,
	\scale, Scale.minor,
	\degree, Pseq([0, 2, 4], inf),
	\octave, 5,
	\dur, 50,
	\legato, exprand(1.0, 2.0)
)
)
~midiPattern.play;
~midiPattern.stop;

