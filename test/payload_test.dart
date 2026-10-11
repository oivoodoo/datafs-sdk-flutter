import "package:datafs_sdk/datafs_sdk.dart";
import "package:test/test.dart";

void main() {
  test("stripUrl drops the query and the hash", () {
    expect(
      stripUrl("https://example.com/pricing?utm_source=hn&q=1#top"),
      "https://example.com/pricing",
    );
  });

  test("campaign keeps three utm fields", () {
    expect(
      campaignOf("https://example.com/a?utm_source=hn&utm_medium=social&utm_campaign=launch&utm_term=nope"),
      {"s": "hn", "m": "social", "c": "launch"},
    );
  });

  test("props reject an email", () {
    expect(() => assertProps({"mail": "a@b.co"}), throwsA(isA<DatafsException>()));
  });
}
