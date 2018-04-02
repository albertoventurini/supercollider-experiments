(
s.meter;
s.freqscope;
s.plotTree;
)

(
var g0 = Group.new(s); // g0 = main synth group
var g1 = Group.after(g0); // g1 = effect group

var b0 = Bus.audio(s);
var b1 = Bus.audio(s);

var makeSlider, makeChoice, makeButton;
var busses = Dictionary.new(0);

var notes = Array.newClear(128);

var reverb = nil;
var reverbEnabled = false;

Window.closeAll;
w = Window("gui", Rect(750, 50, 1200, 800)).front;
w.view.decorator_(FlowLayout(w.bounds, 15@15, 7@7));

makeButton = {
    var button = Button(w, 50@50)
    .states_([
        ["OFF", Color.black, Color.gray],
        ["ON", Color.black, Color.green]
    ])
    .action_({ |obj|
        reverbEnabled = (obj.value == 1);
        obj.value.postln;
    });
};

makeButton.value();

makeChoice = {
    arg name, items, initValue = 0;
    var view, menu, bus;

	bus = Bus.control(s);
    busses.put(name, bus);

    view = CompositeView(w, 200@100);

    menu = PopUpMenu(view, 200@50)
    .items_(items)
    .action_({ |obj|
        obj.value.postln;
        bus.set(obj.value);
    });

    StaticText(view, Rect(0, 60, 80, 20)).string_(name);

    menu.valueAction = initValue;
};

makeChoice.value("osc1_type", items: [\sin, \tri, \saw, \pulse]);
makeChoice.value("osc1_octave", items: [-2, -1, 0, 1, 2], initValue: 2);
makeChoice.value("osc2_type", items: [\sin, \tri, \saw, \pulse]);
makeChoice.value("osc2_octave", items: [-2, -1, 0, 1, 2], initValue: 2);
makeChoice.value("osc3_type", items: [\sin, \tri, \saw, \pulse]);
makeChoice.value("osc3_octave", items: [-2, -1, 0, 1, 2], initValue: 2);

makeSlider = {
    arg name, min = 0, max = 1, initValue = 0, exponential = false;
    var view, slider, numberBox, value, onUpdate, valToSlider, sliderToVal, bus;

    bus = Bus.control(s);
    busses.put(name, bus);
    bus.set(initValue);

    onUpdate = { |val|
        val.postln;
        bus.set(val);
    };

    // Transform a number from the range (min, max) to the range (0, 1)
    valToSlider = { |val|
        if(exponential, val.explin(min, max, 0, 1), val.linlin(min, max, 0, 1));
    };

    // Transform a number in the range (0, 1) to the range (min, max)
    sliderToVal = { |val|
        if(exponential, val.linexp(0, 1, min, max), val.linlin(0, 1, min, max));
    };

    view = CompositeView(w, 120@200);
    slider = Slider(view, Rect(0, 0, 30, 120));
    numberBox = NumberBox(view, Rect(0, 125, 80, 25)).clipLo_(min).clipHi_(max).decimals_(4);

    slider.action = { |obj|
        var val = sliderToVal.value(obj.value);
        numberBox.value_(val);
        onUpdate.value(val);
    };

    numberBox.action = { |obj|
        var sliderVal = valToSlider.value(obj.value);
        slider.value_(sliderVal);
        onUpdate.value(obj.value);
    };

    StaticText(view, Rect(0, 150, 80, 20)).string_(name);

    numberBox.valueAction_(initValue);
};

makeSlider.value("lfo1_freq", 0, 10, 1);
makeSlider.value("osc1_amp", 0, 1, 0.1);
makeSlider.value("osc2_amp", 0, 1, 0.1);
makeSlider.value("osc3_amp", 0, 1, 0.1);
makeSlider.value("osc1_detune", 0.9, 1.1, 1);
makeSlider.value("osc2_detune", 0.9, 1.1, 1);
makeSlider.value("osc3_detune", 0.9, 1.1, 1);
makeSlider.value("osc1_pw", 0, 1, 0.7);
makeSlider.value("osc2_pw", 0, 1, 0.34);
makeSlider.value("osc3_pw", 0, 1, 0.49);
makeSlider.value("attack", 0, 5, 0.1);
makeSlider.value("decay", 0, 1, 0);
makeSlider.value("sustain", 0, 1, 1);
makeSlider.value("release", 0, 5, 1);
makeSlider.value("filter_cutoff", 220, 15000, 220, exponential: true);
makeSlider.value("filter_res", 0.05, 0.95, 0.5);
makeSlider.value("filter_attack", 0, 5, 0);
makeSlider.value("filter_decay", 0, 1, 0);
makeSlider.value("filter_sustain", 0, 1, 1);
makeSlider.value("filter_release", 0, 5, 5);
makeSlider.value("gain", 0, 1, 0.2);


SynthDef.new(\synth, {
	arg freq = 440, outbus = 0, gate = 1, amp = 0.5, ffreqBus = 0, rqBus = 0;
    var osc1, osc2, osc3, lfo1, sig, env, ffreq, rq, pw1, pw2, pw3, fenv, getOsc, gain;

    lfo1 = SinOsc.kr(In.kr(busses["lfo1_freq"])).range(0.9, 1.1);

    getOsc = { |name|
		var detune = In.kr(busses[name ++ "_detune"]);
		var amp = In.kr(busses[name ++ "_amp"]);
		var pulseWidth = In.kr(busses[name ++ "_pw"]);
		var octave = pow(2, In.kr(busses[name ++ "_octave"]) - 2);

		Select.ar(which: In.kr(busses[name ++ "_type"]), array: [
			SinOsc.ar(freq * detune * octave, mul: amp)!2,
			LFTri.ar(freq * detune * octave, mul: amp)!2,
			VarSaw.ar(freq * detune * octave, width: pulseWidth * lfo1, mul: amp)!2,
			Pulse.ar(freq * detune * octave, width: pulseWidth * lfo1, mul: amp)!2
		]);
    };

    osc1 = getOsc.value("osc1");
    osc2 = getOsc.value("osc2");
    osc3 = getOsc.value("osc3");

    env = EnvGen.kr(Env.adsr(In.kr(busses["attack"]), In.kr(busses["decay"]), In.kr(busses["sustain"]), In.kr(busses["release"])), gate, doneAction: 2);

    sig = Mix.ar([osc1, osc2, osc3]);
    gain = In.kr(busses["gain"]);
    sig = sig * env * amp * gain;

    ffreq = In.kr(busses["filter_cutoff"]);
    fenv = EnvGen.kr(Env.adsr(In.kr(busses["filter_attack"]), In.kr(busses["filter_decay"]), In.kr(busses["filter_sustain"]), In.kr(busses["filter_release"])), gate, doneAction: 2);
    ffreq = ffreq * fenv;
	rq = In.kr(busses["filter_res"]);
    sig = RLPF.ar(sig, ffreq, rq);

    Out.ar(outbus, sig);

}).add;

SynthDef.new(\reverb, {
    arg inbus, outbus;
    Out.ar(outbus, JPverb.ar(in: In.ar(inbus)));
}).add;

MIDIdef.noteOn(\noteOn, {
    arg vel, nn, chan, src;

    var outbus = if(reverbEnabled, { b0 }, { 0 });

    [vel, nn, chan, src].postln;
    notes[nn] = Synth.new(\synth, [
        \freq, nn.midicps,
        \gate, 1,
        \outbus, outbus,
    ], target: g0);

    if(reverbEnabled && (reverb == nil), {
        reverb = Synth.new(\reverb, [
            \inbus, b0,
            \outbus, 0
        ], target: g1);
    });
});

MIDIdef.noteOff(\noteOff, {
    arg vel, nn;
    [vel, nn].postln;
    notes[nn].set(\gate, 0);
    notes[nn] = nil;
});

)

(
MIDIClient.init;
MIDIIn.connectAll;
)

(
~notes = [30, 34, 37, 42, 46, 49];

p = Pdef(\pattern,
    Pbind(
        \instrument, \synth,
        \midinote, Prand(~notes.collect({ |n| n + 12 }), inf),
        \dur, 0.25
    )
).play;


)

p.stop;