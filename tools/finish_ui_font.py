"""Keep the original bitmap font and its two runtime color transforms."""
from pathlib import Path
import json
from PIL import Image
import numpy as np
root=Path(__file__).resolve().parents[1]/'godot/assets/ui'
m=json.loads((root/'manifest.json').read_text())
source=root/m['font1']['file'];rgba=np.array(Image.open(source).convert('RGBA'))
child=rgba.copy();child[:,:,:3]=np.clip(rgba[:,:,:3].astype(int)+[50,-30,-30],0,255)
Image.fromarray(child).save(source.with_name('font1_child.png'))
black=rgba.copy();black[:,:,:3]=0
Image.fromarray(black).save(source.with_name('font1_black.png'))
print('Original menu child and keycap font colors prepared')

from PIL import ImageFilter
mask=Image.new('L',(82,82),0)
mask.paste(255,(16,16,66,66))
mask=mask.filter(ImageFilter.BoxBlur(8)).point(lambda v:min(255,v*2))
glow=Image.new('RGBA',(82,82),(255,255,0,0));glow.putalpha(mask)
glow.save(root/'select/hidden_glow.png')
