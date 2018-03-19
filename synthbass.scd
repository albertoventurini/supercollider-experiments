// An attempt to reproduce the patch at https://music.tutsplus.com/tutorials/essential-synthesis-part-3-synth-bass--audio-6844
// I'm not quite there yet...

(
SynthDef.new(\synthbass, {

	arg freq = 440, ffreq = 3000, amp = 1, gate = 1, rq = 0.5;
	var sig, env, fenv, sig1, sig2, sig3;

	env = EnvGen.kr(Env.adsr(0.005, 0, 1, 0.01), gate, doneAction: 2);

	sig1 = SinOsc.ar(freq / 2) * 1.5;
	sig2 = Mix.ar([sig1, Saw.ar(freq)]);
	sig3 = Mix.ar([sig1, Saw.ar(freq * 1.015)]);

	sig2 = sig2 * env * amp;
	sig3 = sig3 * env * amp;

	fenv = EnvGen.kr(Env.adsr(0.001, 0.3, 200 / ffreq, 0.1), gate);

	sig2 = RLPF.ar(sig2, ffreq * fenv, rq);
	sig3 = RLPF.ar(sig3, ffreq * fenv, rq);

	sig = Pan2.ar([sig2, sig3], SinOsc.kr(1));
	Out.ar(0, sig);


}).add;
)

(
p = Pdef(\pattern,
	Pbind(
		\instrument, \synthbass,
		\dur, Pseq([1, 1, 0.5, 1, 0.5].collect({ |i| i / 3 }), inf),
		\midinote, Pseq([0, 0, 0, 2, 3].collect({ |i| i + 36 }), inf)
	)
);
p.play;
)

FreqScope.new;

// PBinds generate events. It's like a stream of events. We can look at each Event object
// by polling the stream.
// Events are objects containing key-value pairs, e.g.:
// ( 'instrument': synthbass, 'dur': 0.33333333333333, 'midinote': 36 )
// The key-value pairs are used to control synths.
// See http://doc.sccode.org/Tutorials/A-Practical-Guide/PG_03_What_Is_Pbind.html
// See http://doc.sccode.org/Tutorials/A-Practical-Guide/PG_07_Value_Conversions.html
// for an explanation of how Event values are converted into SynthDef inputs.

p.asStream.next(Event.new);

// We can play a stream of events:
p.play;


// Midi input
(

var keys = Array.newClear(128);

MIDIClient.init;
MIDIIn.connectAll;

~noteOnFunc = {arg src, chan, num, vel;
	var node;
	node = keys.at(num);
	if (node.notNil, {
		node.release;
		keys.put(num, nil);
	});
	node = Synth.new(\synthbass, [\freq, num.midicps, \amp, vel/1500]);
	keys.put(num, node);
	[chan,num,vel/1500].postln;
};
MIDIIn.addFuncTo(\noteOn, ~noteOnFunc);

~noteOffFunc = {arg src, chan, num, vel;
	var node;
	node = keys.at(num);
	if (node.notNil, {
		node.release;
		keys.put(num, nil);
	});
};
MIDIIn.addFuncTo(\noteOff, ~noteOffFunc);

)

// cleanup
(
MIDIIn.removeFuncFrom(\noteOn, ~noteOnFunc);
MIDIIn.removeFuncFrom(\noteOff, ~noteOffFunc);
)