"""Extract the compiler subset of the already approved HARMAN Mac SDK."""
import concurrent.futures, json, pathlib, struct, urllib.request, zlib
root = pathlib.Path(__file__).resolve().parents[1]
out = root / 'research/tools/air-sdk'
url = 'https://airsdk.harman.com/api/versions/51.4.1.1/sdks/AIRSDK_MacOS.zip?license=accepted'
index = json.loads((root / 'research/tools/sdk-zip-index.json').read_text())
chosen = [e for e in index if (e['name'].startswith('lib/') and e['name'].count('/') == 1 and e['name'].endswith('.jar')) or e['name'] in ['bin/mxmlc', 'bin/amxmlc', 'frameworks/libs/air/airglobal.swc', 'frameworks/libs/air/airglobal.abc', 'frameworks/air-config.xml']]
def extract(e):
    path = out / e['name']
    if path.exists() and path.stat().st_size == e['size']:
        return 'exists ' + e['name']
    start = e['offset']; end = start + e['compressed'] + 4096
    request = urllib.request.Request(url, headers={'Range': f'bytes={start}-{end}', 'Accept-Encoding': 'identity'})
    with urllib.request.urlopen(request, timeout=120) as response:
        if response.status != 206:
            raise RuntimeError('Server did not return a byte range')
        data = response.read()
    h = struct.unpack('<4s5H3I2H', data[:30])
    assert h[0] == b'PK\x03\x04'
    name_len, extra_len = h[-2:]
    packed = data[30+name_len+extra_len:30+name_len+extra_len+e['compressed']]
    content = zlib.decompress(packed, -15) if e['method'] == 8 else packed
    assert len(content) == e['size']
    path.parent.mkdir(parents=True, exist_ok=True); path.write_bytes(content)
    if e['name'].startswith('bin/'): path.chmod(0o755)
    return 'extracted ' + e['name']
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
    for result in pool.map(extract, chosen): print(result, flush=True)
