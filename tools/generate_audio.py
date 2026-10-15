"""Original deterministic Foley/ambience. Stdlib only; no sampled material."""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
ROOT = Path(__file__).resolve().parents[1] / "assets" / "audio"


def bell(t, pitch, decay=3.0):
    return sum(math.sin(math.tau * pitch * ratio * t) * math.exp(-t * decay * (1 + i * .35)) / (1 + i * 2)
               for i, ratio in enumerate((1, 2.76, 4.07, 5.43)))


def render(name, seconds, recipe, seed):
    rng = random.Random(seed)
    samples = []
    smooth = 0.0
    for i in range(round(seconds * RATE)):
        t = i / RATE
        noise = rng.uniform(-1, 1)
        smooth = smooth * .97 + noise * .03
        value = recipe(t, noise, smooth)
        # Short fades and conservative headroom; never clipped PCM.
        fade = min(1, t / .008, (seconds - t) / .04)
        samples.append(value * max(0, fade))
    peak = max(abs(v) for v in samples) or 1
    gain = min(1, .7 / peak)
    ROOT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(ROOT / (name + ".wav")), "wb") as wav:
        wav.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        wav.writeframes(b"".join(struct.pack("<h", round(v * gain * 32767)) for v in samples))
    rms = math.sqrt(sum((v * gain) ** 2 for v in samples) / len(samples))
    assert peak * gain <= .701 and rms > .001
    print(f"{name}: {seconds}s, peak={peak * gain:.3f}, rms={rms:.3f}")


if __name__ == "__main__":
    render("camp", 12, lambda t, n, s: s * (.6 + .2 * math.sin(math.tau * t / 12)) + n * .017 * (.5 + .5 * math.sin(t * 17) ** 16), 7419)
    render("hunt", 12, lambda t, n, s: s * .55 + .028 * math.sin(math.tau * 55 * t) * (.7 + .3 * math.cos(math.tau * t / 12)), 7420)
    render("reward", 1.8, lambda t, n, s: .28 * bell(t, 330) + (.18 * bell(t - .18, 440) if t >= .18 else 0), 1)
    render("strike", .32, lambda t, n, s: n * .32 * math.sin(math.pi * min(1, t / .25)) ** 2 * math.exp(-t * 9), 2)
    render("impact", .5, lambda t, n, s: .3 * n * math.exp(-t * 20) + .27 * math.sin(math.tau * (95 * t - 25 * t * t)) * math.exp(-t * 13), 3)
    render("resonance", 1, lambda t, n, s: .3 * bell(t, 220, 5), 4)
    render("victory", 2.5, lambda t, n, s: sum(.17 * bell(t - delay, pitch, 2.8) for delay, pitch in ((0, 220), (.23, 293.665), (.46, 330)) if t >= delay), 5)
