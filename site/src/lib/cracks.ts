import { mulberry32, hashSeed } from "./prng";

export interface CrackPath {
  d: string;
  depth: number;
  delay: number;
}

export interface CrackNetwork {
  width: number;
  height: number;
  paths: CrackPath[];
}

interface GrowOptions {
  maxDepth: number;
  branchProb: number;
  angleJitter: number;
  lengthDecay: number;
  segLength: number;
}

// generateCracks grows a Lichtenberg-style branching fracture network from a
// handful of origin points along the bottom edge, as if the ground were
// splitting from heat below. Each continuous run (before a branch forks off)
// becomes one SVG path so strokes join smoothly; branches taper in width and
// opacity with depth. Deterministic per seed so the mark doesn't reshuffle
// between builds.
export function generateCracks(
  seed: string,
  width: number,
  height: number,
  opts: Partial<GrowOptions> = {}
): CrackNetwork {
  const rand = mulberry32(hashSeed(seed));
  const options: GrowOptions = {
    maxDepth: 7,
    branchProb: 0.38,
    angleJitter: 0.4,
    lengthDecay: 0.8,
    segLength: height * 0.16,
    ...opts,
  };

  const paths: CrackPath[] = [];
  const originCount = 3 + Math.floor(rand() * 2);

  function grow(x: number, y: number, angle: number, length: number, depth: number, points: [number, number][]) {
    if (depth > options.maxDepth || length < 3) {
      if (points.length > 1) emit(points, depth);
      return;
    }
    const jitter = (rand() - 0.5) * options.angleJitter;
    const nextAngle = angle + jitter;
    const nx = x + Math.cos(nextAngle) * length;
    const ny = y + Math.sin(nextAngle) * length;
    points.push([nx, ny]);

    const shouldBranch = depth > 1 && rand() < options.branchProb;
    if (shouldBranch) {
      emit(points, depth);
      const branchAngle = nextAngle + (rand() < 0.5 ? -1 : 1) * (0.5 + rand() * 0.6);
      grow(nx, ny, branchAngle, length * options.lengthDecay * 0.75, depth + 1, [[nx, ny]]);
      grow(nx, ny, nextAngle, length * options.lengthDecay, depth + 1, [[nx, ny]]);
    } else {
      grow(nx, ny, nextAngle, length * options.lengthDecay, depth + 1, points);
    }
  }

  function emit(points: [number, number][], depth: number) {
    if (points.length < 2) return;
    const d = points.map(([px, py], i) => `${i === 0 ? "M" : "L"}${px.toFixed(1)} ${py.toFixed(1)}`).join(" ");
    paths.push({ d, depth, delay: rand() * 4 });
  }

  for (let i = 0; i < originCount; i++) {
    const x = width * (0.25 + rand() * 0.5);
    const y = height + 4;
    const angle = -Math.PI / 2 + (rand() - 0.5) * 0.6;
    grow(x, y, angle, options.segLength, 0, [[x, y]]);
  }

  return { width, height, paths };
}
