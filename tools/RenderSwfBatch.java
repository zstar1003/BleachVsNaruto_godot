import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.awt.image.BufferedImage;
import javax.imageio.ImageIO;
import com.jpexs.decompiler.flash.SWF;
import com.jpexs.decompiler.flash.tags.DefineSpriteTag;
import com.jpexs.decompiler.flash.timeline.Timeline;
import com.jpexs.decompiler.flash.types.RECT;
import com.jpexs.decompiler.flash.exporters.commonshape.Matrix;

/** Load a SWF once and render a TSV list: id, destination, count, outer-frame. */
public class RenderSwfBatch {
 public static void main(String[] args) throws Exception {
  SWF swf = new SWF(new FileInputStream(args[0]), true);
  for(String line: Files.readAllLines(Path.of(args[1]))) {
   if(line.isBlank())continue;
   String[] fields=line.split("\t");int id=Integer.parseInt(fields[0]);
   DefineSpriteTag sprite=(DefineSpriteTag)swf.getCharacter(id);
   Timeline timeline=sprite.getTimeline();RECT b=sprite.getRect();
   RECT bounds=new RECT(b.Xmin-80,b.Xmax+80,b.Ymin-80,b.Ymax+80);
   File dir=new File(fields[1]);dir.mkdirs();
   if(new File(dir,"frames.json").exists())continue;
   int count=fields.length>2?Integer.parseInt(fields[2]):timeline.getFrameCount();
   int outer=fields.length>3?Integer.parseInt(fields[3]):-1;
   Map<String,String> unique=new HashMap<>();
   try(PrintWriter out=new PrintWriter(new File(dir,"frames.json.tmp"))) {
    out.print("[");
    for(int f=0;f<count;f++) {
     BufferedImage im=SWF.frameToImageGet(timeline,outer<0?f:outer,outer<0?0:f,null,0,bounds,new Matrix(),null,null,1.0,true,1).getBufferedImage();
     int w=im.getWidth(),h=im.getHeight();int[] pixels=im.getRGB(0,0,w,h,null,0,w);
     int x0=w,y0=h,x1=-1,y1=-1;
     for(int y=0;y<h;y++)for(int x=0;x<w;x++)if((pixels[y*w+x]>>>24)>0){x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y);}
     if(f>0)out.print(",");if(x1<0){out.print("null");continue;}
     BufferedImage trim=im.getSubimage(x0,y0,x1-x0+1,y1-y0+1);
     int[] trimmed=trim.getRGB(0,0,trim.getWidth(),trim.getHeight(),null,0,trim.getWidth());
     // SHA-256 prevents accidental reuse of different images.
     java.security.MessageDigest md=java.security.MessageDigest.getInstance("SHA-256");
     for(int px:trimmed){md.update((byte)(px>>>24));md.update((byte)(px>>>16));md.update((byte)(px>>>8));md.update((byte)px);}
     String key=trim.getWidth()+"x"+trim.getHeight()+":"+HexFormat.of().formatHex(md.digest());
     String file=unique.get(key);
     if(file==null){file=String.format("%04d.png",f+1);ImageIO.write(trim,"png",new File(dir,file));unique.put(key,file);}
     out.print("{\"file\":\""+file+"\",\"offset\":["+(bounds.Xmin/20.0+x0)+","+(bounds.Ymin/20.0+y0)+"]}");
    }
    out.print("]");
   }
   Files.move(new File(dir,"frames.json.tmp").toPath(),new File(dir,"frames.json").toPath(),StandardCopyOption.REPLACE_EXISTING);
   System.out.println(id+" "+count+" frames / "+unique.size()+" images "+dir);System.out.flush();
  }
 }
}
