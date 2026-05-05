import { EventEmitter } from 'node:events';
import { generateKeyPairSync } from 'node:crypto';
import type * as http2 from 'node:http2';
import { describe, expect, it, vi } from 'vitest';
import type { WatchNotificationsSettings } from '@agent-pulse/shared';
import {
  buildApnsJwt,
  buildWatchPushPayload,
  checkWatchNotificationsConfig,
  deliverWatchNotifications,
  sendApnsPush
} from './watch-push';

describe('watch APNs delivery', () => {
  it('builds an ES256 APNs provider JWT with the configured team and key ids', () => {
    const privateKey = testPrivateKey();
    const jwt = buildApnsJwt({
      teamId: 'TEAM123456',
      keyId: 'KEY1234567',
      privateKey,
      issuedAtSeconds: 1_775_000_000
    });

    const [header, payload, signature] = jwt.split('.');

    expect(JSON.parse(Buffer.from(header, 'base64url').toString('utf8'))).toEqual({
      alg: 'ES256',
      kid: 'KEY1234567'
    });
    expect(JSON.parse(Buffer.from(payload, 'base64url').toString('utf8'))).toEqual({
      iss: 'TEAM123456',
      iat: 1_775_000_000
    });
    expect(Buffer.from(signature, 'base64url')).toHaveLength(64);
  });

  it('sends the minimal payload to the correct APNs HTTP/2 endpoint and headers', async () => {
    const privateKey = testPrivateKey();
    const captured: {
      authority?: string;
      headers?: http2.OutgoingHttpHeaders;
      body?: string;
    } = {};
    const close = vi.fn();
    const connect = vi.fn((authority: string) => {
      captured.authority = authority;
      return {
        request(headers: http2.OutgoingHttpHeaders) {
          captured.headers = headers;
          return new FakeHttp2Stream((body) => {
            captured.body = body;
          }) as unknown as http2.ClientHttp2Stream;
        },
        close
      } as unknown as http2.ClientHttp2Session;
    });

    await sendApnsPush({
      token: 'watch-token',
      topic: 'com.paulfecto.AgentPulse.watchkitapp',
      environment: 'sandbox',
      teamId: 'TEAM123456',
      keyId: 'KEY1234567',
      privateKey,
      issuedAtSeconds: 1_775_000_000,
      connect,
      payload: buildWatchPushPayload({
        kind: 'attention',
        threadId: 'thread-1',
        serverName: 'Agent Pulse',
        title: 'Agent needs you',
        body: 'A pending approval is waiting.'
      })
    });

    expect(captured.authority).toBe('https://api.sandbox.push.apple.com');
    expect(captured.headers).toMatchObject({
      ':method': 'POST',
      ':path': '/3/device/watch-token',
      'apns-topic': 'com.paulfecto.AgentPulse.watchkitapp',
      'apns-push-type': 'alert',
      authorization: expect.stringMatching(/^bearer /)
    });
    expect(JSON.parse(captured.body ?? '{}')).toEqual({
      kind: 'attention',
      threadId: 'thread-1',
      serverName: 'Agent Pulse',
      aps: {
        alert: {
          title: 'Agent needs you',
          body: 'A pending approval is waiting.'
        },
        sound: 'default'
      }
    });
    expect(close).toHaveBeenCalledTimes(1);
  });

  it('returns config errors without throwing when disabled or missing APNs key material', async () => {
    await expect(checkWatchNotificationsConfig(settings({ enabled: false }))).resolves.toEqual({
      ok: false,
      error: 'Watch notifications are disabled.'
    });
    await expect(
      deliverWatchNotifications({
        settings: settings({ keyPath: '/does/not/exist/AuthKey_KEY1234567.p8' }),
        targets: [{ deviceId: 'device-1', token: 'token-1' }],
        notification: {
          kind: 'finished',
          threadId: 'thread-1',
          serverName: 'Agent Pulse',
          title: 'Agent finished',
          body: 'Open Agent Pulse to review the result.'
        }
      })
    ).resolves.toMatchObject({
      ok: false,
      delivered: 0,
      failed: 1,
      error: expect.stringContaining('Could not read APNs key file')
    });
  });

  it('keeps notification payloads free of transcript and raw provider data', () => {
    const payload = buildWatchPushPayload({
      kind: 'errored',
      threadId: 'thread-1',
      serverName: 'Agent Pulse',
      title: 'Agent errored',
      body: 'Tap to open the thread.'
    });

    expect(payload).toEqual({
      kind: 'errored',
      threadId: 'thread-1',
      serverName: 'Agent Pulse',
      aps: {
        alert: {
          title: 'Agent errored',
          body: 'Tap to open the thread.'
        },
        sound: 'default'
      }
    });
    expect(JSON.stringify(payload)).not.toMatch(/message|transcript|raw|providerData/i);
  });
});

class FakeHttp2Stream extends EventEmitter {
  constructor(private readonly captureBody: (body: string) => void) {
    super();
  }

  setEncoding(): void {
    // no-op test stream
  }

  end(body: string): void {
    this.captureBody(body);
    queueMicrotask(() => {
      this.emit('response', { ':status': 200 });
      this.emit('end');
    });
  }
}

function testPrivateKey(): string {
  const { privateKey } = generateKeyPairSync('ec', { namedCurve: 'P-256' });
  return privateKey.export({ type: 'pkcs8', format: 'pem' }).toString();
}

function settings(overrides: Partial<WatchNotificationsSettings> = {}): WatchNotificationsSettings {
  return {
    enabled: true,
    teamId: 'TEAM123456',
    keyId: 'KEY1234567',
    bundleId: 'com.paulfecto.AgentPulse.watchkitapp',
    environment: 'sandbox',
    keyPath: '/tmp/AuthKey_KEY1234567.p8',
    lastError: '',
    lastCheckedAt: null,
    ...overrides
  };
}
