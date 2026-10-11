# datafs_sdk

Flutter tracker for a self-hosted DataFS install. MIT. Dart SDK >= 3.3.

```dart
import "package:datafs_sdk/datafs_sdk.dart";

final dfs = Datafs(domain: "example.com", endpoint: "https://analytics.example.com");

await dfs.pageview(url: "https://example.com/pricing");
await dfs.event("signup", props: {"plan": "pro"}, url: "https://example.com/pricing");
```

The package sets no cookies and does not retry. See `API.md`.

`flutter test` needs a Flutter SDK. `dart test` covers the payload helpers. `package:test` is a dev dependency you add locally if it is not already on the machine; the assertions above match that package.
