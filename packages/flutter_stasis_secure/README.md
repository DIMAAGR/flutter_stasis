# flutter_stasis_secure

Optional secure persistence helpers for `flutter_stasis` `SafeData`.

This package keeps secure storage concerns out of `flutter_stasis_core` and
`flutter_stasis`, while still giving you an explicit way to persist selected
values such as refresh tokens.

## Installation

```yaml
dependencies:
  flutter_stasis_secure: ^0.1.0
```

## What this package provides

- `SafeDataSecureAdapter` for pluggable backends
- `FakeSafeDataSecureAdapter` for tests and local development
- `SafeDataSecureBinding<T>` for explicit persist and restore flows
- `SafeDataSecureRecord` as the storage payload model

## Explicit persistence example

```dart
final refreshToken = SafeData<String>(
  policy: const SafeDataPolicy(
    persistence: SafeDataPersistence.secureStorage,
    logStrategy: SafeDataLogStrategy.redacted,
  ),
);

final binding = SafeDataSecureBinding<String>(
  field: refreshToken,
  adapter: adapter,
  key: 'refresh_token',
  encode: (value) => value,
  decode: (value) => value,
);

await binding.persist(); // explicit
await binding.restore(); // explicit
await binding.deletePersisted();
```

The binding is intentionally imperative. Nothing is restored automatically.

## Design notes

- Use `SafeDataPersistence.secureStorage` on the field policy when the value is
  allowed to be persisted securely.
- Keep restore explicit to avoid surprising sensitive values appearing in
  memory.
- Use a fake adapter in tests and wire a real plugin backend later.

## Status

This package currently ships the contract and a fake in-memory adapter. A real
plugin-backed adapter can be added on top without changing the core Stasis
packages.
