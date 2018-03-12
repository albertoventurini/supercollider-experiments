/*
Notes

- If you set the decay just over the delay value, it produces a very interesting effect (e.g. decay = 0.6, delay = 0.5)
- However there are very audible "clicks", especially when the cutoff frequency is low.

- Delay = 0.2, Decay = 0.6875 -> Nice
*/

// Busses

(
~cutoff = Bus.control(s, 1);
~cutoff.set(220);

~atk = Bus.control(s, 1);
~atk.set(0);

~decay = Bus.control(s, 1);
~decay.set(0);

~gain = Bus.control(s, 1);
~gain.set(0);

~res = Bus.control(s, 1);
~res.set(0);

~delay = Bus.control(s, 1);
~delay.set(0.5);

)


// Synth

(
SynthDef.new(\filtered, {

	arg freq = 440, cutoff = 440;
	var sig, env, envDelay;

	sig = 0;

	4.do {
		sig = sig + VarSaw.ar(
			freq * {Rand(0.995, 1.005)}!2,
			{Rand(0, 1)}!2,
			{ExpRand(0.005, 0.05)}!2
		);
	};

	env = EnvGen.kr(
		Env.perc(In.kr(~atk), In.kr(~decay), 1, -3),
		doneAction: 2
	);

	//sig = LPF.ar(sig, cutoff);
//	sig = RLPF.ar(sig, In.kr(~cutoff), In.kr(~res));
	//sig = sig + CombL.ar(sig, 0.3, 0.3, 3);

	//sig = FreeVerb.ar(sig, 0.5, 0.5, 0.1);
	sig = sig * env * In.kr(~gain);

	sig = sig + (CombC.ar(sig, In.kr(~delay), In.kr(~delay), 2, 1) );

	sig = RLPF.ar(sig, In.kr(~cutoff), In.kr(~res));


	Out.ar(0, sig);

}).add;
)

// GUI

(
Window.closeAll;
w = Window("gui", Rect(750, 50, 700, 700))
.front;

StaticText(w, Rect(180, 20, 150, 30)).string_("Cutoff");

Slider(w, Rect(280, 20, 150, 30))
.action_({
	arg obj;
	var qual;
	qual = obj.value.linexp(0, 1, 220, 10000);
	qual.postln;
	~cutoff.set(qual);
});

StaticText(w, Rect(180, 60, 150, 30)).string_("Resonance");

Slider(w, Rect(280, 60, 150, 30))
.action_({
	arg obj;
	var qual;
	qual = obj.value.linlin(0, 1, 2, 0);
	qual.postln;
	~res.set(qual);
});

StaticText(w, Rect(180, 100, 150, 30)).string_("Attack");

Slider(w, Rect(280, 100, 150, 30))
.action_({
	arg obj;
	var qual;
	qual = obj.value.linlin(0, 1, 0, 2);
	qual.postln;
	~atk.set(qual);
});

StaticText(w, Rect(180, 140, 150, 30)).string_("Decay");

Slider(w, Rect(280, 140, 150, 30))
.action_({
	arg obj;
	var qual;
	qual = obj.value.linlin(0, 1, 0, 2);
	qual.postln;
	~decay.set(qual);
});

StaticText(w, Rect(180, 180, 150, 30)).string_("Gain");

Slider(w, Rect(280, 180, 150, 30))
.action_({
	arg obj;
	var qual;
	qual = obj.value.linlin(0, 1, 0, 0.1);
	qual.postln;
	~gain.set(qual);
});

StaticText(w, Rect(180, 220, 150, 30)).string_("Delay");

Slider(w, Rect(280, 220, 150, 30))
.action_({
	arg obj;
	var qual;
	qual = obj.value.linlin(0, 1, 0, 0.5);
	qual.postln;
	~delay.set(qual);
});

f = FreqScopeView(w, Rect(0, 350, 700, 350));
f.active_(true); // turn it on the first time;
w.onClose_({ f.kill }); // you must have this

)

// Pattern

(
p = Pdef(\pattern,
	Pbind(
		\instrument, \filtered,
		\dur, Pseq(8.collect({0.1}), inf),
		\midinote, Pseq([47, 50, 52, 54, 57, 59, 62, 64], inf),
	)
).play;
)


FreqScope.new;