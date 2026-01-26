import hmac
import hashlib

class PagerDutyVerifier:
    def __init__(self, key, version):
        self.key = key
        self.version = version

    def verify(self, payload, signatures):
        comparisons = []
        byte_key = self.key.encode("ASCII")
        signature = hmac.new(byte_key, payload.encode(), hashlib.sha256).hexdigest()
        signatureWithVersion = self.version + "=" + signature
        signatureList = signatures.split(",")

        for _signature in signatureList:
            comparisons.append(hmac.compare_digest(signatureWithVersion, _signature))

        return any(comparisons)

if __name__ == "__main__":
    import sys

    if len(sys.argv) < 3:
        print("Usage: verify.py <shared-secret> <provided-signatures> [version-prefix]", file=sys.stderr)
        sys.exit(1)

    key = sys.argv[1]
    signatures = sys.argv[2]
    version = sys.argv[3] if len(sys.argv) > 3 else ""

    payload = sys.stdin.read()

    verifier = PagerDutyVerifier(key, version)

    if verifier.verify(payload, signatures):
        print("Signature verified")
        sys.exit(0)
    else:
        print("Signature verification failed", file=sys.stderr)
        sys.exit(1)
