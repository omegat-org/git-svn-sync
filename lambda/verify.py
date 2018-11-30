import hmac
import hashlib

# Implements verification of requests from Apache Allura
# See https://forge-allura.apache.org/p/allura/wiki/Webhooks/

with open('secret') as in_file:
    secret = in_file.read().strip()


def verify(payload, signature, secret):
    actual_signature = hmac.new(secret.encode(
        'utf-8'), payload.encode('utf-8'), hashlib.sha1)
    actual_signature = 'sha1=' + actual_signature.hexdigest()
    return hmac.compare_digest(actual_signature, signature)


def verify_event(event):
    try:
        body = event['body']
        signature = event['headers']['X-Allura-Signature']
        return verify(body, signature, secret)
    except Exception as e:
        print(e)
        return False
