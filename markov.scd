//direct node definition

(
m = MarkovSet([
	[100, [120, 130]],
	[120, [100, 1900]],
	[130, nil]
]);
)
8.do{ m.next(100).postln};
8.do{ m.next(120).postln};
8.do{ m.next(130).postln};

//training by a stream
(
m = MarkovSet.fill(100, Pseq([1,2,3,4, Prand([5, 55, 555])], inf).asStream);
)

8.do { m.next(1).postln };
8.do { m.next(4).postln };
8.do { m.next(55).postln };

//training by bit

m = MarkovSet.new;
m.read(\x, \y);
m.read(\x, \z);
m.read(\z, \abcde);
m.read(\y, nil);

8.do { m.next(\x).postln };
8.do { m.next(\y).postln };
8.do { m.next(\z).postln };

m.read(\y, \mmmm);
8.do { m.next(\y).postln };

//creating streams
(
m = MarkovSet([
	[100, [120, 130]],
	[120, [100, 190]],
	[130, [100]],
	[1900, [1000, 2000, 3000]]
]);
)
m.makeSeeds;
x = m.asStream;
32.do { x.next.postln };


//spy out a stream to feed it in
z = Pseq([100, 200, 300, Prand([1.2, 1.4, 1.5])], inf).asStream;
z = Pspy(m, z).asStream;
32.do { x.next.postln };
15.do { z.next };
32.do { x.next.postln };

//event streams
(
SynthDef("mark", { arg out, freq, sustain=1, amp=0.1, pan;
    var env, u=1;
    env = EnvGen.kr(Env.perc(0.03, sustain, 5), 1, doneAction:2);
    3.do { var d; d = exprand(0.01, 1); u = SinOsc.ar(d * 300, u, rrand(0.1, 0.4) * d, 1) };
    Out.ar(out, Pan2.ar(SinOsc.ar(u + 1 * freq, 0, amp * env), pan));

}).store;
)

(
a = Pbind(
	\freq, Pshuf([203, 490, 231, 764, 234], inf),
	\dur, Pshuf([0.5, 0.5, 1.0, 0.25, 0.125, 0.5], inf)
);
m = MarkovSet.fill(20, Pevent(a, Event.default).asStream);
)
(
m.dict.keysValuesDo{
	|key, val|
	postf("Key: %\t\tvalue: %\n", key, val)
};
)
b = Pchain(Pfsm2(m), (instrument: \mark));
c = Pchain(a, (instrument: \mark));
Ppar([b, c]).play;

//supermarkov
m = MarkovSet;
m.parseFile("Help/More-On-Getting-Help.html".standardizePath);
m.parseFile("Help/Language/Intro-to-Objects.html".standardizePath);

//m.writeHtml(nPages: 5, pagelength: 120);

(
x = Pfsm2(m, inf).asStream;
300.do{ x.next.post };
)





















