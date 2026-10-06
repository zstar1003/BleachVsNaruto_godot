// Uses FFDec's renderer; only the imported frame imagery is rasterized here.
import java.io.*;
import java.awt.image.BufferedImage;
import javax.imageio.ImageIO;
import com.jpexs.decompiler.flash.SWF;
import com.jpexs.decompiler.flash.tags.DefineSpriteTag;
import com.jpexs.decompiler.flash.timeline.Timeline;
import com.jpexs.decompiler.flash.types.RECT;
import com.jpexs.decompiler.flash.exporters.commonshape.Matrix;

public class RenderSwf {
 public static void main(String[] args) throws Exception {
  SWF swf = new SWF(new FileInputStream(args[0]), true);
  int id = Integer.parseInt(args[1]);
  Timeline timeline = id == 0 ? swf.getTimeline() : ((DefineSpriteTag)swf.getCharacter(id)).getTimeline();
  RECT bounds = id == 0 ? swf.getRect() : ((DefineSpriteTag)swf.getCharacter(id)).getRect();
  bounds = new RECT(bounds.Xmin-80,bounds.Xmax+80,bounds.Ymin-80,bounds.Ymax+80);
  File dir = new File(args[2]); dir.mkdirs();
  PrintWriter out = new PrintWriter(new File(dir,"frames.json")); out.print("[");
  System.out.println("Bounds " + bounds + " frames " + timeline.getFrameCount());
  int count = args.length > 3 ? Integer.parseInt(args[3]) : timeline.getFrameCount();
  for(int f=0;f<count;f++) {
   BufferedImage im = SWF.frameToImageGet(timeline,args.length > 3 ? 0 : f,args.length > 3 ? f : 0,null,0,bounds,new Matrix(),null,null,1.0,true,1).getBufferedImage();
   int x0=im.getWidth(),y0=im.getHeight(),x1=-1,y1=-1;
   for(int y=0;y<im.getHeight();y++) for(int x=0;x<im.getWidth();x++) if((im.getRGB(x,y)>>>24)>0) {x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y);}
   if(f>0)out.print(",");
   if(x1<0){out.print("null");continue;}
   String file=String.format("%04d.png",f+1);
   ImageIO.write(im.getSubimage(x0,y0,x1-x0+1,y1-y0+1),"png",new File(dir,file));
   out.print("{\"file\":\""+file+"\",\"offset\":["+(bounds.Xmin/20.0+x0)+","+(bounds.Ymin/20.0+y0)+"]}");
   if(f%100==0) System.out.println("Rendered "+(f+1));
  }
  out.print("]");out.close();
 }
}
