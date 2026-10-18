/** Deterministic PRNG (mulberry32) so the mock dataset is identical on every load. */
export class Rng {
  private s: number;
  constructor(seed: number) {
    this.s = seed >>> 0;
  }
  next(): number {
    this.s = (this.s + 0x6d2b79f5) >>> 0;
    let t = this.s;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  }
  int(min: number, max: number): number {
    return Math.floor(this.next() * (max - min + 1)) + min;
  }
  float(min: number, max: number): number {
    return this.next() * (max - min) + min;
  }
  pick<T>(arr: readonly T[]): T {
    return arr[Math.floor(this.next() * arr.length)]!;
  }
  chance(p: number): boolean {
    return this.next() < p;
  }
  weighted<T>(items: readonly [T, number][]): T {
    const total = items.reduce((s, [, w]) => s + w, 0);
    let r = this.next() * total;
    for (const [v, w] of items) {
      if (r < w) return v;
      r -= w;
    }
    return items[items.length - 1]![0];
  }
  hex(n: number): string {
    let out = "";
    for (let i = 0; i < n; i++) out += Math.floor(this.next() * 16).toString(16);
    return out;
  }
  uuid(): string {
    return `${this.hex(8)}-${this.hex(4)}-4${this.hex(3)}-${this.pick(["8", "9", "a", "b"])}${this.hex(3)}-${this.hex(12)}`;
  }
  shuffle<T>(arr: T[]): T[] {
    const a = [...arr];
    for (let i = a.length - 1; i > 0; i--) {
      const j = Math.floor(this.next() * (i + 1));
      [a[i], a[j]] = [a[j]!, a[i]!];
    }
    return a;
  }
}
