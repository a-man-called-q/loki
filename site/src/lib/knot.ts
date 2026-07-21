import { mulberry32, hashSeed } from "./prng";

export interface KnotBand {
  width: number;
  height: number;
  strandEmber: string[];
  strandStone: string[];
}

interface KnotOptions {
  wavelength: number;
  amplitude: number;
  gap: number;
  step: number;
}

// generateKnotBand weaves two sine strands of opposite phase across a
// horizontal band, breaking whichever strand should read as "underneath" at
// each crossing so the two ribbons read as interlaced rope rather than an
// X-ing pair of lines — the same trick real interlace knotwork uses, just
// computed instead of hand-drawn. Returns each strand as an array of
// already-gapped sub-paths.
export function generateKnotBand(seed: string, width: number, height: number, opts: Partial<KnotOptions> = {}): KnotBand {
  const rand = mulberry32(hashSeed(seed));
  const options: KnotOptions = {
    wavelength: 56,
    amplitude: height * 0.34,
    gap: 6,
    step: 2,
    ...opts,
  };
  const { wavelength, amplitude, gap, step } = options;
  const mid = height / 2;
  const wobble = 0.06 + rand() * 0.04;

  function yA(x: number): number {
    return mid + Math.sin((x / wavelength) * Math.PI * 2) * amplitude * (1 - wobble + wobble * Math.sin(x * 0.01));
  }
  function yB(x: number): number {
    return mid - Math.sin((x / wavelength) * Math.PI * 2) * amplitude * (1 - wobble + wobble * Math.cos(x * 0.013));
  }

  const crossings: number[] = [];
  for (let cx = wavelength / 2; cx < width; cx += wavelength / 2) crossings.push(cx);

  function isGapped(x: number, strand: "A" | "B"): boolean {
    for (let i = 0; i < crossings.length; i++) {
      const cx = crossings[i];
      if (Math.abs(x - cx) < gap) {
        const aOver = i % 2 === 0;
        return strand === "A" ? !aOver : aOver;
      }
    }
    return false;
  }

  function buildPaths(fn: (x: number) => number, strand: "A" | "B"): string[] {
    const paths: string[] = [];
    let current: [number, number][] = [];
    for (let x = 0; x <= width; x += step) {
      if (isGapped(x, strand)) {
        if (current.length > 1) paths.push(toPath(current));
        current = [];
        continue;
      }
      current.push([x, fn(x)]);
    }
    if (current.length > 1) paths.push(toPath(current));
    return paths;
  }

  function toPath(points: [number, number][]): string {
    return points.map(([px, py], i) => `${i === 0 ? "M" : "L"}${px.toFixed(1)} ${py.toFixed(1)}`).join(" ");
  }

  return {
    width,
    height,
    strandEmber: buildPaths(yA, "A"),
    strandStone: buildPaths(yB, "B"),
  };
}
