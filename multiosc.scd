(
s.meter;
s.freqscope;
s.plotTree;
)

///////////////////////////////////////////////////////////////////////////
// Busses
(
~g0 = Group.new(s); // g0 = main synth group
~g1 = Group.after(~g0); // g1 = effect group

~b0 = Bus.audio(s);
~b1 = Bus.audio(s);

~c0 = Bus.control(s);
~c0.set(0);

~c1 = Bus.control(s);
~c1.set(0);

~c2 = Bus.control(s);
~c2.set(1);
)

///////////////////////////////////////////////////////////////////////////
// Main synth
//
// Three pulse oscillators with a touch of pulse width modulation.
// Two oscillators are slightly detuned.
(
SynthDef.new(\synth, {
    arg freq = 440, outbus = 0, pw1 = 0.7, pw2 = 0.34, pw3 = 0.49, gate = 1, amp = 0.2, ffreqBus = 0, rqBus = 0;
    var osc1, osc2, osc3, lfo1, sig, env, ffreq, rq;

    lfo1 = SinOsc.kr(2).range(0.95, 1.05);
    osc1 = Pulse.ar(freq, pw1*lfo1, 0.2)!2;
    osc2 = Pulse.ar((freq*0.991) / 2, pw2*lfo1, 0.2)!2;
    osc3 = Pulse.ar(freq*1.004, pw3*lfo1, 0.2)!2;

    env = EnvGen.kr(Env.asr(0.01, 1, 1), gate, doneAction: 2);

    sig = Mix.ar([osc1, osc2, osc3]);
    sig = sig * env * amp;

    ffreq = In.kr(ffreqBus).linexp(0, 127, 220, 15000);
    rq = In.kr(rqBus).linlin(0, 127, 0.05, 0.95);
    sig = RLPF.ar(sig, ffreq, rq);

    Out.ar(outbus, sig);

}).add;
)

///////////////////////////////////////////////////////////////////////////
// FX synth - reverb
(
SynthDef.new(\reverb, {
    arg inbus, outbus, sizeBus;

    Out.ar(outbus, JPverb.ar(in: In.ar(inbus), size: In.kr(sizeBus)));
}).add;

r = Synth.new(\reverb, [
    \inbus, ~b0,
    \outbus, 0,
    \sizeBus, ~c2
], target: ~g1);
)



///////////////////////////////////////////////////////////////////////////
// MIDI init
(
MIDIClient.init;
MIDIIn.connectAll;
)

///////////////////////////////////////////////////////////////////////////
// MIDI defs
(
var notes = Array.newClear(128);

MIDIdef.noteOn(\noteOn, {
    arg vel, nn, chan, src;
    [vel, nn, chan, src].postln;
    notes[nn] = Synth.new(\synth, [
        \freq, nn.midicps,
        \gate, 1,
        \outbus, ~b0,
        \ffreqBus, ~c0,
        \rqBus, ~c1
    ], ~g0);
});

MIDIdef.noteOff(\noteOff, {
    arg vel, nn;
    [vel, nn].postln;
    notes[nn].set(\gate, 0);
    notes[nn] = nil;
});

MIDIdef.cc(\modwheel, {
    arg val, num, chan, src;
    [val, num, chan, src].postln;

    // 1 is the modulation wheel
    if(num == 1, {
        ~c0.set(val);
    });

    // 7 is the volume
    if(num == 7, {
        ~c2.set(val);
    });
});
)

///////////////////////////////////////////////////////////////////////////
// MIDI cleanup
(
MIDIdef.freeAll;
)

