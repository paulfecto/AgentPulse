import * as http2 from 'node:http2';
import { createSign } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import type { WatchNotificationsSettings, WatchPushEnvironment } from '@agent-pulse/shared';

export type WatchNotificationKind = 'finished' | 'errored' | 'attention';

export type WatchNotificationInput = {
  kind: WatchNotificationKind;
  threadId: string;
  serverName: string;
  title: string;
  body: string;
};

export type WatchPushTarget = {
  deviceId: string;
  token: string;
  bundleId?: string;
  environment?: WatchPushEnvironment;
};

export type WatchPushPayload = {
  kind: WatchNotificationKind;
  threadId: string;
  serverName: string;
  aps: {
    alert: {
      title: string;
      body: string;
    };
    sound: 'default';
  };
};

export type WatchPushDeliveryResult = {
  ok: boolean;
  delivered: number;
  failed: number;
  error?: string;
};

type SendApnsPushOptions = {
  token: string;
  topic: string;
  environment: WatchPushEnvironment;
  teamId: string;
  keyId: string;
  privateKey: string;
  payload: WatchPushPayload;
  issuedAtSeconds?: number;
  connect?: (authority: string) => http2.ClientHttp2Session;
};

export type DeliverWatchNotificationsOptions = {
  settings: WatchNotificationsSettings;
  targets: WatchPushTarget[];
  notification: WatchNotificationInput;
  now?: () => Date;
  connect?: (authority: string) => http2.ClientHttp2Session;
};

export function buildWatchPushPayload(input: WatchNotificationInput): WatchPushPayload {
  return {
    kind: input.kind,
    threadId: input.threadId,
    serverName: input.serverName,
    aps: {
      alert: {
        title: input.title,
        body: input.body
      },
      sound: 'default'
    }
  };
}

export function validateWatchNotificationsConfig(settings: WatchNotificationsSettings): { ok: true } | { ok: false; error: string } {
  if (!settings.enabled) {
    return { ok: false, error: 'Watch notifications are disabled.' };
  }
  if (!settings.teamId.trim()) {
    return { ok: false, error: 'Apple Team ID is required.' };
  }
  if (!settings.keyId.trim()) {
    return { ok: false, error: 'Apple APNs Key ID is required.' };
  }
  if (!settings.bundleId.trim()) {
    return { ok: false, error: 'Watch app bundle id is required.' };
  }
  if (!settings.keyPath.trim()) {
    return { ok: false, error: 'APNs .p8 key path is required.' };
  }
  return { ok: true };
}

export async function checkWatchNotificationsConfig(
  settings: WatchNotificationsSettings
): Promise<{ ok: true } | { ok: false; error: string }> {
  const validation = validateWatchNotificationsConfig(settings);
  if (!validation.ok) {
    return validation;
  }

  try {
    const privateKey = await readFile(settings.keyPath, 'utf8');
    if (!privateKey.includes('PRIVATE KEY')) {
      return { ok: false, error: 'APNs key file does not look like a private key.' };
    }
  } catch (error) {
    const detail = error instanceof Error ? error.message : String(error);
    return { ok: false, error: `Could not read APNs key file: ${detail}` };
  }

  return { ok: true };
}

export function buildApnsJwt(input: {
  teamId: string;
  keyId: string;
  privateKey: string;
  issuedAtSeconds?: number;
}): string {
  const issuedAtSeconds = input.issuedAtSeconds ?? Math.floor(Date.now() / 1000);
  const header = base64UrlJson({ alg: 'ES256', kid: input.keyId });
  const payload = base64UrlJson({ iss: input.teamId, iat: issuedAtSeconds });
  const signingInput = `${header}.${payload}`;
  const signer = createSign('sha256');
  signer.update(signingInput);
  signer.end();
  const signature = signer.sign(input.privateKey);
  return `${signingInput}.${derToJoseSignature(signature, 32).toString('base64url')}`;
}

export async function sendApnsPush(options: SendApnsPushOptions): Promise<void> {
  const authority =
    options.environment === 'production'
      ? 'https://api.push.apple.com'
      : 'https://api.sandbox.push.apple.com';
  const jwt = buildApnsJwt({
    teamId: options.teamId,
    keyId: options.keyId,
    privateKey: options.privateKey,
    issuedAtSeconds: options.issuedAtSeconds
  });
  const client = (options.connect ?? http2.connect)(authority);

  try {
    await new Promise<void>((resolve, reject) => {
      const stream = client.request({
        ':method': 'POST',
        ':path': `/3/device/${options.token}`,
        authorization: `bearer ${jwt}`,
        'apns-topic': options.topic,
        'apns-push-type': 'alert',
        'apns-priority': '10',
        'content-type': 'application/json'
      });
      let statusCode = 0;
      let body = '';
      stream.setEncoding('utf8');
      stream.on('response', (headers) => {
        const status = headers[':status'];
        statusCode = typeof status === 'number' ? status : Number(status ?? 0);
      });
      stream.on('data', (chunk) => {
        body += String(chunk);
      });
      stream.on('end', () => {
        if (statusCode >= 200 && statusCode < 300) {
          resolve();
          return;
        }
        reject(new Error(`APNs responded with ${statusCode || 'unknown status'}${body ? `: ${body}` : ''}`));
      });
      stream.on('error', reject);
      stream.end(JSON.stringify(options.payload));
    });
  } finally {
    client.close();
  }
}

export async function deliverWatchNotifications(
  options: DeliverWatchNotificationsOptions
): Promise<WatchPushDeliveryResult> {
  if (options.targets.length === 0) {
    return { ok: true, delivered: 0, failed: 0 };
  }

  const validation = validateWatchNotificationsConfig(options.settings);
  if (!validation.ok) {
    return { ok: false, delivered: 0, failed: options.targets.length, error: validation.error };
  }

  let privateKey: string;
  try {
    privateKey = await readFile(options.settings.keyPath, 'utf8');
  } catch (error) {
    const detail = error instanceof Error ? error.message : String(error);
    return {
      ok: false,
      delivered: 0,
      failed: options.targets.length,
      error: `Could not read APNs key file: ${detail}`
    };
  }

  const payload = buildWatchPushPayload(options.notification);
  const issuedAtSeconds = Math.floor((options.now?.() ?? new Date()).getTime() / 1000);
  let delivered = 0;
  let failed = 0;
  let firstError: string | undefined;

  for (const target of options.targets) {
    const topic = target.bundleId?.trim() || options.settings.bundleId.trim();
    const environment = target.environment ?? options.settings.environment;
    try {
      await sendApnsPush({
        token: target.token,
        topic,
        environment,
        teamId: options.settings.teamId.trim(),
        keyId: options.settings.keyId.trim(),
        privateKey,
        payload,
        issuedAtSeconds,
        connect: options.connect
      });
      delivered += 1;
    } catch (error) {
      failed += 1;
      firstError ??= error instanceof Error ? error.message : String(error);
    }
  }

  return {
    ok: failed === 0,
    delivered,
    failed,
    ...(firstError ? { error: firstError } : {})
  };
}

function base64UrlJson(value: unknown): string {
  return Buffer.from(JSON.stringify(value)).toString('base64url');
}

function derToJoseSignature(signature: Buffer, partLength: number): Buffer {
  let offset = 0;
  if (signature[offset++] !== 0x30) {
    throw new Error('Invalid ECDSA signature.');
  }
  const sequenceLength = readDerLength(signature, () => offset, (next) => {
    offset = next;
  });
  if (sequenceLength <= 0 || offset + sequenceLength > signature.length) {
    throw new Error('Invalid ECDSA signature length.');
  }
  const r = readDerInteger(signature, () => offset, (next) => {
    offset = next;
  });
  const s = readDerInteger(signature, () => offset, (next) => {
    offset = next;
  });
  return Buffer.concat([leftPadInteger(r, partLength), leftPadInteger(s, partLength)]);
}

function readDerInteger(
  signature: Buffer,
  getOffset: () => number,
  setOffset: (nextOffset: number) => void
): Buffer {
  let offset = getOffset();
  if (signature[offset++] !== 0x02) {
    throw new Error('Invalid ECDSA integer.');
  }
  const length = readDerLength(signature, () => offset, (next) => {
    offset = next;
  });
  const integer = signature.subarray(offset, offset + length);
  setOffset(offset + length);
  return trimLeadingZeros(integer);
}

function readDerLength(
  signature: Buffer,
  getOffset: () => number,
  setOffset: (nextOffset: number) => void
): number {
  let offset = getOffset();
  const first = signature[offset++];
  if (first === undefined) {
    throw new Error('Invalid ECDSA length.');
  }
  if ((first & 0x80) === 0) {
    setOffset(offset);
    return first;
  }
  const byteCount = first & 0x7f;
  if (byteCount === 0 || byteCount > 2) {
    throw new Error('Unsupported ECDSA length.');
  }
  let length = 0;
  for (let index = 0; index < byteCount; index += 1) {
    const byte = signature[offset++];
    if (byte === undefined) {
      throw new Error('Invalid ECDSA length.');
    }
    length = (length << 8) | byte;
  }
  setOffset(offset);
  return length;
}

function trimLeadingZeros(input: Buffer): Buffer {
  let offset = 0;
  while (offset < input.length - 1 && input[offset] === 0) {
    offset += 1;
  }
  return input.subarray(offset);
}

function leftPadInteger(input: Buffer, length: number): Buffer {
  if (input.length > length) {
    return input.subarray(input.length - length);
  }
  if (input.length === length) {
    return input;
  }
  return Buffer.concat([Buffer.alloc(length - input.length), input]);
}
