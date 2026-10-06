"""Check that the Mac bundle retains every original asset and selection target."""
import hashlib
import lzma
import pathlib
import struct
import xml.etree.ElementTree as ET
import zlib

ROOT = pathlib.Path(__file__).resolve().parents[1]
ORIGINAL = ROOT / 'research/release/swf_output'
BUNDLE = ROOT / 'BleachVsNaruto-3.4-Mac.app/Contents/Resources'

def swf_frames(path):
    data = path.read_bytes()
    length = struct.unpack_from('<I', data, 4)[0]
    signature = data[:3]
    if signature == b'CWS':
        body = zlib.decompress(data[8:])
    elif signature == b'ZWS':
        properties = data[12:17]
        prop = properties[0]
        body = lzma.decompress(data[17:], format=lzma.FORMAT_RAW, filters=[{
            'id': lzma.FILTER_LZMA1,
            'dict_size': int.from_bytes(properties[1:], 'little'),
            'lc': prop % 9, 'lp': prop // 9 % 5, 'pb': prop // 45,
        }])
    else:
        assert signature == b'FWS', path
        body = data[8:]
    assert len(body) + 8 == length, path
    rect_bytes = (5 + (body[0] >> 3) * 4 + 7) // 8
    return struct.unpack_from('<H', body, rect_bytes + 2)[0]

assets = [p for p in (ORIGINAL / 'assets').rglob('*') if p.is_file() and p.name != '.gitkeep']
for source in [ORIGINAL / 'FighterTester.swf', *assets]:
    target = BUNDLE / source.relative_to(ORIGINAL)
    assert target.is_file(), target
    assert hashlib.sha256(source.read_bytes()).digest() == hashlib.sha256(target.read_bytes()).digest(), target

frames = {str(p.relative_to(ORIGINAL)): swf_frames(p) for p in (ORIGINAL / 'assets').rglob('*.swf')}
counts = {}
ids = {}
for kind in ['fighter', 'assistant', 'map']:
    tree = ET.parse(ORIGINAL / 'assets/config' / (kind + '.xml')).getroot()
    ids[kind] = {entry.attrib['id'] for entry in tree}
    playable = [entry for entry in tree if entry.find('file') is not None]
    counts[kind] = len(playable)
    for entry in playable:
        file = entry.find('file')
        url = file.attrib['url']
        assert (ORIGINAL / url).is_file(), url
        if url in frames:
            assert 1 <= int(file.attrib.get('startFrame', '1')) <= frames[url], entry.attrib['id']

selection = ET.parse(ORIGINAL / 'assets/config/select.xml').getroot()
for section, kind in [('char_list', 'fighter'), ('assist_list', 'assistant')]:
    for item in selection.find(section).iter('item'):
        for identifier in [item.text, item.attrib.get('more')]:
            if identifier:
                assert identifier in ids[kind], identifier

print('Original asset hashes retained:', len(assets), '+ FighterTester.swf')
print('Playable entries including forms:', counts)
print('SWF integrity, frame indices and selection references: PASS')
