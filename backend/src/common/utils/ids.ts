import { randomBytes, createHash, randomInt } from 'node:crypto';

export const randomToken = (bytes = 32) => randomBytes(bytes).toString('base64url');
export const sha256 = (s: string) => createHash('sha256').update(s).digest('hex');
export const numericCode = (len: number) => Array.from({ length: len }, () => randomInt(0, 10)).join('');
export const shortToken = () => randomBytes(9).toString('base64url');
