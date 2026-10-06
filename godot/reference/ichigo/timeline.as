package ichigo_fla
{
   import flash.accessibility.*;
   import flash.display.*;
   import flash.errors.*;
   import flash.events.*;
   import flash.filters.*;
   import flash.geom.*;
   import flash.media.*;
   import flash.net.*;
   import flash.net.drm.*;
   import flash.system.*;
   import flash.text.*;
   import flash.text.ime.*;
   import flash.ui.*;
   import flash.utils.*;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol632")]
   public dynamic class mc_0059_1 extends MovieClip
   {
      
      public var AImain:MovieClip;
      
      public var bdmn:MovieClip;
      
      public var bs1atm:MovieClip;
      
      public var bsatm:MovieClip;
      
      public var cbsatm:MovieClip;
      
      public var k1atm:MovieClip;
      
      public var k2atm:MovieClip;
      
      public var k3atm:MovieClip;
      
      public var kj1atm:MovieClip;
      
      public var kj21atm:MovieClip;
      
      public var kj2atm:MovieClip;
      
      public var sbsatm:MovieClip;
      
      public var sh12atm:MovieClip;
      
      public var sh1atm:MovieClip;
      
      public var sh22atm:MovieClip;
      
      public var sh2atm:MovieClip;
      
      public var tkatm:MovieClip;
      
      public var tzatm:MovieClip;
      
      public var zh1atm:MovieClip;
      
      public var zh2_chkm:MovieClip;
      
      public var zh2atm:MovieClip;
      
      public var zh3atm:MovieClip;
      
      public function mc_0059_1()
      {
         super();
         addFrameScript(11,this.frame12,19,this.frame20,25,this.frame26,34,this.frame35,45,this.frame46,48,this.frame49,78,this.frame79,86,this.frame87,88,this.frame89,93,this.frame94,97,this.frame98,102,this.frame103,103,this.frame104,109,this.frame110,118,this.frame119,128,this.frame129,130,this.frame131,134,this.frame135,138,this.frame139,145,this.frame146,147,this.frame148,151,this.frame152,159,this.frame160,161,this.frame162,165,this.frame166,172,this.frame173,183,this.frame184,186,this.frame187,189,this.frame190,196,this.frame197,198,this.frame199,199,this.frame200,203,this.frame204,226,this.frame227,238,this.frame239,249,this.frame250,257,this.frame258,262,this.frame263,264,this.frame265,274,this.frame275,280,this.frame281,287,this.frame288,298,this.frame299,306,this.frame307,307,this.frame308,319,this.frame320,320,this.frame321,327,this.frame328,340,this.frame341,368,this.frame369,372,this.frame373,374,this.frame375,382,this.frame383,390,this.frame391,405,this.frame406,409,this.frame410,410
         ,this.frame411,422,this.frame423,447,this.frame448,451,this.frame452,452,this.frame453,455,this.frame456,465,this.frame466,487,this.frame488,515,this.frame516,516,this.frame517,518,this.frame519,526,this.frame527,529,this.frame530,548,this.frame549,550,this.frame551,579,this.frame580,599,this.frame600,618,this.frame619,630,this.frame631,636,this.frame637,650,this.frame651,660,this.frame661,673,this.frame674,689,this.frame690,694,this.frame695,716,this.frame717,727,this.frame728,831,this.frame832,851,this.frame852,921,this.frame922,944,this.frame945,965,this.frame966,971,this.frame972,1036,this.frame1037,1056,this.frame1057,1058,this.frame1059,1076,this.frame1077,1081,this.frame1082);
      }
      
      internal function frame12() : *
      {
         parent.$effect_ctrler.walk();
      }
      
      internal function frame20() : *
      {
         parent.$effect_ctrler.walk();
      }
      
      internal function frame26() : *
      {
         parent.$mc_ctrler.loop("走");
      }
      
      internal function frame35() : *
      {
         parent.$mc_ctrler.setBisha();
         parent.$mc_ctrler.setBishaUP();
         parent.$mc_ctrler.setBishaSUPER();
         parent.$mc_ctrler.dash(2.5);
         parent.$effect_ctrler.dash();
         parent.$effect_ctrler.shadow(-200,-200,-200);
      }
      
      internal function frame46() : *
      {
         parent.$mc_ctrler.dashStop();
      }
      
      internal function frame49() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame79() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame87() : *
      {
         parent.$mc_ctrler.setAirMove(true);
      }
      
      internal function frame89() : *
      {
         parent.$effect_ctrler.playSoundHit1();
      }
      
      internal function frame94() : *
      {
         parent.$mc_ctrler.setSkillAIR();
      }
      
      internal function frame98() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame103() : *
      {
         parent.$mc_ctrler.move(0,-5);
         parent.$mc_ctrler.damping(0,0.5);
      }
      
      internal function frame104() : *
      {
         parent.$mc_ctrler.addQi(5);
      }
      
      internal function frame110() : *
      {
         parent.$effect_ctrler.shine(65535);
         parent.$mc_ctrler.fire("tzatm",{
            "x":{
               "start":5,
               "add":1,
               "max":15
            },
            "y":{
               "start":5,
               "add":1,
               "max":15
            },
            "hold":2,
            "hits":1
         });
      }
      
      internal function frame119() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame129() : *
      {
         parent.$mc_ctrler.movePercent(0.25,0);
      }
      
      internal function frame131() : *
      {
         parent.$effect_ctrler.playSoundHit1();
      }
      
      internal function frame135() : *
      {
         parent.$mc_ctrler.setAttack("砍2");
         parent.$mc_ctrler.setZhao1();
         parent.$mc_ctrler.setBisha();
         parent.$mc_ctrler.stopMove();
      }
      
      internal function frame139() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame146() : *
      {
         parent.$mc_ctrler.movePercent(0.5,0);
      }
      
      internal function frame148() : *
      {
         parent.$effect_ctrler.playSoundHit1();
      }
      
      internal function frame152() : *
      {
         parent.$mc_ctrler.setBishaSUPER();
         parent.$mc_ctrler.setAttack("砍3");
         parent.$mc_ctrler.setSkill2();
         parent.$mc_ctrler.setZhao2();
         parent.$mc_ctrler.stopMove();
      }
      
      internal function frame160() : *
      {
         parent.$mc_ctrler.endAct();
      }
      
      internal function frame162() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame166() : *
      {
         parent.$mc_ctrler.movePercent(0.5,0);
         parent.$mc_ctrler.dampingPercent(0.05,0);
         parent.$effect_ctrler.playSoundHit2();
      }
      
      internal function frame173() : *
      {
         parent.$mc_ctrler.setZhao2();
         parent.$mc_ctrler.setZhao3();
         parent.$mc_ctrler.setSkill1();
         parent.$mc_ctrler.setDash();
      }
      
      internal function frame184() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame187() : *
      {
         parent.$mc_ctrler.addQi(10);
      }
      
      internal function frame190() : *
      {
         parent.$mc_ctrler.setSteelBody(true);
      }
      
      internal function frame197() : *
      {
         parent.$effect_ctrler.shine(16750848);
         parent.$effect_ctrler.shake(0,2);
      }
      
      internal function frame199() : *
      {
         parent.$mc_ctrler.setSteelBody(false);
      }
      
      internal function frame200() : *
      {
         parent.$effect_ctrler.shake(0,2);
      }
      
      internal function frame204() : *
      {
         parent.$mc_ctrler.endAct();
      }
      
      internal function frame227() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame239() : *
      {
         parent.$mc_ctrler.addQi(5);
      }
      
      internal function frame250() : *
      {
         parent.$effect_ctrler.shine(65535);
      }
      
      internal function frame258() : *
      {
         parent.$mc_ctrler.setBishaUP();
         parent.$mc_ctrler.setJump();
      }
      
      internal function frame263() : *
      {
         parent.$mc_ctrler.endAct();
      }
      
      internal function frame265() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame275() : *
      {
         parent.$mc_ctrler.addQi(5);
      }
      
      internal function frame281() : *
      {
         parent.$effect_ctrler.shine(65535);
         parent.$mc_ctrler.fire("zh1atm",{
            "x":{
               "start":10,
               "add":1,
               "max":20
            },
            "hold":60,
            "hits":1
         });
      }
      
      internal function frame288() : *
      {
         parent.$mc_ctrler.endAct();
      }
      
      internal function frame299() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame307() : *
      {
         parent.$mc_ctrler.addQi(10);
      }
      
      internal function frame308() : *
      {
         parent.$mc_ctrler.movePercent(3);
         parent.$mc_ctrler.setHitTarget("zh2_chkm","招2_CHK");
         parent.$effect_ctrler.dash();
         parent.$effect_ctrler.shadow(-200,-200,-200);
      }
      
      internal function frame320() : *
      {
         parent.$mc_ctrler.dampingPercent(0.6);
         parent.$effect_ctrler.playSoundHit2();
      }
      
      internal function frame321() : *
      {
         parent.$mc_ctrler.setSteelBody(false);
         parent.$effect_ctrler.endShadow();
         parent.$effect_ctrler.shine(65535);
      }
      
      internal function frame328() : *
      {
         parent.$mc_ctrler.setBishaSUPER();
         parent.$mc_ctrler.setBisha();
         parent.$mc_ctrler.setZhao1();
         parent.$mc_ctrler.setZhao3();
      }
      
      internal function frame341() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame369() : *
      {
         parent.$mc_ctrler.addQi(5);
      }
      
      internal function frame373() : *
      {
         parent.$effect_ctrler.shine(65535);
      }
      
      internal function frame375() : *
      {
         parent.$mc_ctrler.fire("zh3atm",{
            "x":{
               "start":5,
               "add":2,
               "max":15
            },
            "y":{
               "start":-2,
               "add":-0.5,
               "max":-15
            },
            "hold":60,
            "hits":1
         });
      }
      
      internal function frame383() : *
      {
         parent.$mc_ctrler.endAct();
         parent.$mc_ctrler.setDash();
         parent.$mc_ctrler.setJump();
      }
      
      internal function frame391() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame406() : *
      {
         parent.$mc_ctrler.addQi(10);
      }
      
      internal function frame410() : *
      {
         parent.$effect_ctrler.playSoundHit2();
      }
      
      internal function frame411() : *
      {
         parent.$mc_ctrler.movePercent(1);
         parent.$mc_ctrler.dampingPercent(0.2);
      }
      
      internal function frame423() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame448() : *
      {
         parent.$mc_ctrler.addQi(20);
      }
      
      internal function frame452() : *
      {
         parent.$effect_ctrler.playSoundHit2();
      }
      
      internal function frame453() : *
      {
         parent.$effect_ctrler.shine(65535);
      }
      
      internal function frame456() : *
      {
         parent.$mc_ctrler.endAct();
      }
      
      internal function frame466() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame488() : *
      {
         parent.$effect_ctrler.bisha(false,"Ichigo_1");
      }
      
      internal function frame516() : *
      {
         parent.$effect_ctrler.endBisha();
      }
      
      internal function frame517() : *
      {
         parent.$mc_ctrler.movePercent(0.5);
         parent.$mc_ctrler.dampingPercent(0.05);
      }
      
      internal function frame519() : *
      {
         parent.$effect_ctrler.shine(65535);
         parent.$mc_ctrler.fire("bs1atm",{
            "x":{
               "start":10,
               "add":1,
               "max":20
            },
            "hold":60,
            "hits":1
         });
      }
      
      internal function frame527() : *
      {
         parent.$mc_ctrler.movePercent(0.5);
         parent.$mc_ctrler.dampingPercent(0.05);
      }
      
      internal function frame530() : *
      {
         parent.$effect_ctrler.shine(65535);
         parent.$mc_ctrler.fire("bs1atm",{
            "x":{
               "start":10,
               "add":1,
               "max":20
            },
            "hold":60,
            "hits":1
         });
      }
      
      internal function frame549() : *
      {
         parent.$mc_ctrler.movePercent(0.5);
         parent.$mc_ctrler.dampingPercent(0.05);
      }
      
      internal function frame551() : *
      {
         parent.$effect_ctrler.shine(65535);
         parent.$mc_ctrler.fire("bsatm",{
            "x":{
               "start":20,
               "add":2,
               "max":30
            },
            "hold":60,
            "hits":1,
            "hp":200
         });
      }
      
      internal function frame580() : *
      {
         parent.$mc_ctrler.endAct();
      }
      
      internal function frame600() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame619() : *
      {
         parent.$effect_ctrler.bisha(false,"Ichigo_1");
      }
      
      internal function frame631() : *
      {
         parent.$effect_ctrler.endBisha();
      }
      
      internal function frame637() : *
      {
         parent.$effect_ctrler.shine(65535);
      }
      
      internal function frame651() : *
      {
         parent.$mc_ctrler.endAct();
      }
      
      internal function frame661() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame674() : *
      {
         parent.$effect_ctrler.bisha(true,"Ichigo_2");
      }
      
      internal function frame690() : *
      {
         parent.$effect_ctrler.endBisha();
      }
      
      internal function frame695() : *
      {
         parent.$effect_ctrler.shine(65535);
      }
      
      internal function frame717() : *
      {
         parent.$mc_ctrler.endAct();
      }
      
      internal function frame728() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame832() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame852() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame922() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame945() : *
      {
         parent.$mc_ctrler.stop();
      }
      
      internal function frame966() : *
      {
         parent.$mc_ctrler.stop();
      }
      
      internal function frame972() : *
      {
         parent.$effect_ctrler.startWanKai("Ichigo_3");
      }
      
      internal function frame1037() : *
      {
         parent.$effect_ctrler.shine(9697014);
         parent.$effect_ctrler.startShake(0,3);
      }
      
      internal function frame1057() : *
      {
         parent.$fighter_ctrler.doWanKai();
      }
      
      internal function frame1059() : *
      {
         parent.$effect_ctrler.startWanKai("Ichigo_4");
      }
      
      internal function frame1077() : *
      {
         parent.$fighter_ctrler.addHpLosePercent(0.2);
      }
      
      internal function frame1082() : *
      {
         parent.$fighter_ctrler.doWanKai(4);
      }
   }
}

