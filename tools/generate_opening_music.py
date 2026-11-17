"""Original synthesized opening cues; no external recordings or samples."""
import math, wave, array
from pathlib import Path

SR = 22050
ROOT = Path(__file__).resolve().parents[1] / 'assets/music'

def render(name, bpm, chords, melody, dark=False):
    beat = 60 / bpm
    duration = len(chords) * 4 * beat
    out = [0.0] * int(SR * duration)
    def note(midi, start, length, amp, pluck=False):
        f = 440 * 2 ** ((midi - 69) / 12)
        for j in range(int(length * SR)):
            t = j / SR
            env = min(1, t / (.008 if pluck else .25)) * min(1, (length-t)/.3)
            tone = math.sin(math.tau*f*t) + .18*math.sin(math.tau*f*2*t)
            if pluck: env *= math.exp(-t*3)
            else: tone += .15*math.sin(math.tau*f*1.002*t)
            out[(int(start*SR)+j) % len(out)] += amp * env * tone
    for bar, chord in enumerate(chords):
        start = bar * 4 * beat
        for m in chord: note(m, start, 4*beat+.4, .035)
        note(chord[0]-12, start, 3.8*beat, .055)
        if dark:
            for k,m in enumerate(melody[bar]): note(m,start+k*2*beat,1.8*beat,.065)
            note(chord[2]+12,start+3*beat,beat*1.7,.06,True)
        else:
            for k in range(6): note(chord[[0,1,2,1,2,1][k]]+12,start+k*beat*2/3,beat*1.8,.10,True)
            for k,m in enumerate(melody[bar]): note(m,start+k*beat,beat*.9,.07)
    # Cyclic reflections preserve the loop tail.
    dry=out[:]
    for delay,gain in [(.17,.16),(.31,.09)]:
        offset=int(delay*SR)
        for i,v in enumerate(dry):out[(i+offset)%len(out)]+=v*gain
    pcm=array.array('h',(int(math.tanh(v)*24000) for v in out))
    with wave.open(str(ROOT/name),'wb') as w:
        w.setnchannels(1);w.setsampwidth(2);w.setframerate(SR);w.writeframes(pcm.tobytes())

render('mist_title.wav',78,[[48,55,59],[45,52,55],[41,48,52],[43,50,55]]*2,
       [[79,76,74,72],[76,72,71,67],[72,74,76,79],[74,71,67,71]]*2)
render('mist_history.wav',58,[[45,52,55],[41,48,52],[38,45,53],[40,47,56]]*2,
       [[76,72],[72,69],[69,65],[71,68]]*2,True)
