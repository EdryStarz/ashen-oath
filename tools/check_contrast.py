"""WCAG contrast check for opaque UI tokens; does not claim whole-screen accessibility."""

def luminance(value):
    colors = [int(value[i:i+2], 16) / 255 for i in (0, 2, 4)]
    linear = [x / 12.92 if x <= .04045 else ((x + .055) / 1.055) ** 2.4 for x in colors]
    return sum(x * w for x, w in zip(linear, (.2126, .7152, .0722)))

def ratio(a, b):
    hi, lo = sorted((luminance(a), luminance(b)), reverse=True)
    return (hi + .05) / (lo + .05)

if __name__ == '__main__':
    for text, background in [('eee7d8','101719'),('b5bdb9','101719'),('b5bdb9','1b2426'),('101719','d1b480'),('a6c4ad','101719')]:
        contrast = ratio(text, background)
        assert contrast >= 4.5
        print(f'#{text} / #{background}: {contrast:.2f}:1 PASS')
