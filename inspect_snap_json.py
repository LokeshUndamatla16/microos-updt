import json

with open('/tmp/snap_store_v6.json') as f:
    d = json.load(f)

for c in d.get('channel-map', []):
    track = c.get('channel', {}).get('name')
    if 'stable' in track:
        print(f"Track: {track}, Size: {c.get('download', {}).get('size')} bytes")
        print(f"URL: {c.get('download', {}).get('url')[:100]}...")
