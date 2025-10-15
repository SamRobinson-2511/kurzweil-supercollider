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

