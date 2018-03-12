// Busses

(
~cutoff = Bus.control(s, 1);
~cutoff.set(80);

~atk = Bus.control(s, 1);
~atk.set(0);

~decay = Bus.control(s, 1);
~decay.set(0);

~gain = Bus.control(s, 1);
~gain.set(0);

~bwr = Bus.control(s, 1);
~bwr.set(1);

~pulsewidth = Bus.control(s, 1);
~pulsewidth.set(1);

)

(
SynthDef.new(\saw, {

	arg freq = 440, cutoff = 80, bwr = 1;
	var sig, env;

	sig = Pulse.ar(freq!2 * XLine.kr(1.5, 1, 0.03), 0.2, width: In.kr(~pulsewidth));
	//env = EnvGen.kr(Env.perc());

	env = EnvGen.kr(
		Env.perc(In.kr(~atk), In.kr(~decay), 1, -3),
		doneAction: 2
	);


	//sig = Resonz.ar(sig, In.kr(~cutoff), In.kr(~bwr));
	//sig = BPF.ar(sig, 440, 1);

//	sig = Resonz.ar(sig, In.kr(~cutoff), In.kr(~bwr));
	sig = RLPF.ar(sig, In.kr(~cutoff), In.kr(~bwr));

	sig = sig * env * In.kr(~gain);

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
	qual = obj.value.linexp(0, 1, 20, 21000);
	qual.postln;
	~cutoff.set(qual);
});

StaticText(w, Rect(180, 60, 150, 30)).string_("BWR");

Slider(w, Rect(280, 60, 150, 30))
.action_({
	arg obj;
	var qual;
	qual = obj.value.linlin(0, 1, 0, 10);
	qual.postln;
	~bwr.set(qual);
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
	qual = obj.value;
	qual.postln;
	~gain.set(qual);
});

StaticText(w, Rect(180, 220, 150, 30)).string_("Pulse width");

Slider(w, Rect(280, 220, 150, 30))
.action_({
	arg obj;
	var qual;
	qual = obj.value;
	qual.postln;
	~pulsewidth.set(qual);
});


f = FreqScopeView(w, Rect(0, 350, 700, 350));
f.active_(true); // turn it on the first time;
w.onClose_({ f.kill }); // you must have this

)


(
p = Pdef(\pattern,
	Pbind(
		\instrument, \saw,
		\dur, Pseq(8.collect({0.25}), inf),
		\midinote, Pseq([0, 0, 2, 0, 3, 0, 5, 3].collect({ |n| n + 40 }), inf),
	)
).play;
)

[0,1,2].collect({ |i| i + 30})

FreqScope.new