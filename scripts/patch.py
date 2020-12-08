import json
import sys
import base64


def fail(s):
    print(s)
    exit(1)


print(sys.argv)

if len(sys.argv) < 4:
    fail("usage: {} secret_name secret_value (or k1=v1 k2=v2 ...) file.json".format(sys.argv[0]))

secret_name = sys.argv[1]
if secret_name.startswith('/'):
    secret_name = secret_name[1:]
if not secret_name.startswith('concourse/'):
    fail("invalid secret name {} (must start with concourse/)".format(secret_name))

secret_pairs = []

for arg in sys.argv[2:-1]:
    parts = arg.split('=')
    if len(parts) == 1:
        k = "value"
        v = parts[0]
    elif len(parts) == 2:
        k, v = parts
    else:
        fail("invalid argument {}".format(arg))
    secret_pairs.append({
        'key': k,
        'value': base64.b64encode(v.encode('utf-8')).decode('utf-8'),
    })

with open(sys.argv[-1]) as f:
    file_content = json.load(f)

data = [v for v in file_content['data'] if v['path'] != secret_name] + \
    [{'path': secret_name, 'pairs': secret_pairs}]
data.sort(key=lambda v: v['path'])

file_content['data'] = data

with open(sys.argv[-1], 'w') as f:
    json.dump(file_content, f, indent=4)
