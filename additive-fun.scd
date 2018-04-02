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
~c0.set(100);

~c1 = Bus.control(s);
~c1.set(0);

~c2 = Bus.control(s);
~c2.set(1);
)

l = [1,2,3]
l.add(4)
l

max(3,4)

cos(0)

///////////////////////////////////////////////////////////////////////////
// Main synth
//
(

SynthDef.new(\synth, {
    arg freq = 440, outbus = 0, gate = 1, amp = 0.001;
    var sig = 0, env,
    tot = 70, // how many oscillators will be summed
    freqstep = 0.99, // frequency multiplication factor
    ampmod; // amplitude modulation osc

    // Here we create segments that are used to shape the frequency spectrum.
    //var segments = [[\lin, 0, 0.2, 0.1, 1], [\exp, 0.2, 0.7, 1, 0.5], [\lin, 0.7, 1, 0.5, 0.01]];
    //var segments = [[\exp, 0, 0.2, 1, 0.01], [\exp, 0.2, 0.5, 0.001, 2], [\lin, 0.5, 1, 0.4, 0.01]];

    var segments = [[\exp, 0, 1, 1, 0.01]];
    //var segments = [[\lin, 0, 1, 1, 0.01]];

    //var segments = [ [\exp, 0, 0.3, 1, 0.1], [\lin, 0.3, 0.6, 0.1, 0.8], [\exp, 0.6, 1.0, 0.8, 0.001] ];

    var freqmul = { |i|
        // 'i' is the index of the oscillator whose frequency we'll modulate.

        // Normalized value of 'i'
        var norm = i/tot;

        // Choose the segment we're in for this 'i'
        var segment = segments.select({ |int| (norm >=  int[1]) && (norm < int[2]) })[0];

        if(segments != nil, {
            var symbol = segment[0];

            var start = 0;
            var end = segment[2] - segment[1];
            var valuestart = segment[3];
            var valueend = segment[4];

            // Find out where we are within the given segment
            var position = norm.linlin(0, 1, start, end);

            if(symbol == \lin, {
                // linearly go from start to end
                position.linlin(start, end, valuestart, valueend);
            }, {
                // exponentially go from start to end
                position.linexp(start, end, valuestart, valueend);
            });

        });
    };

    var freqmul2 = { |i|
        var norm = i/tot;

        //1 - sin(norm);
        norm.linexp(0, 1, 1, 0.0001);
    };

    ampmod = SinOsc.kr(3).linlin(-1, 1, 0.95, 1.05);

    tot.do { |i|
        sig = sig + LFTri.ar(
            freq * (i*freqstep + 1) * rrand(0.995, 1.005),
            mul: freqmul2.value(i)
        );
    };

    env = EnvGen.kr(Env.adsr(0.001), gate, doneAction: 2);

    sig = sig * env * amp * 0.3 * ampmod;
    sig = LPF.ar(sig, In.kr(~c0).linlin(0, 127, 200, 18000));
    sig = LPF.ar(sig, EnvGen.kr(Env.new([220, 18000], [0.01])));

    Out.ar(outbus, sig!2);


}).add;
)


///////////////////////////////////////////////////////////////////////////
// FX synth - reverb
(
SynthDef.new(\reverb, {
    arg inbus, outbus;

    Out.ar(outbus, JPverb.ar(in: In.ar(inbus), size: 0.5));
}).add;
)

(
r = Synth.new(\reverb, [
    \inbus, ~b0,
    \outbus, 0
], target: ~g1);
)

r.free;


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
        \rqBus, ~c1,
        \amp, 0.1
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
        ~c1.set(val);
    });
});
)

///////////////////////////////////////////////////////////////////////////
// MIDI cleanup
(
MIDIdef.freeAll;
)



(
var notes = [52, 55, 60, 64, 67, 71, 72, 71, 67, 64 ];
Pdef(\pattern,
    Pbind(
        \instrument, \synth,
        \midinote, Prand(notes.collect({ |n| n - 12 }), inf),
        \amp, Pexprand(0.05, 0.2, inf),
        \sustain, Pexprand(0.05, 0.5, inf),
        \dur, 0.2,
        \outbus, ~b0
    )
).play;
)

Pdef(\pattern).stop;
