package naruto_fla
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
   
   [Embed(source="/_assets/assets.swf", symbol="symbol662")]
   public dynamic class mc_0004_1 extends MovieClip
   {
      
      public var AImain:MovieClip;
      
      public var bdmn:MovieClip;
      
      public var bs1atm:MovieClip;
      
      public var bs3atm:MovieClip;
      
      public var bsatm:MovieClip;
      
      public var cbs1atm:MovieClip;
      
      public var cbs2atm:MovieClip;
      
      public var cbs3atm:MovieClip;
      
      public var cbsmc:MovieClip;
      
      public var k1atm:MovieClip;
      
      public var k3atm:MovieClip;
      
      public var k4atm:MovieClip;
      
      public var kj1_chkm:MovieClip;
      
      public var kj1atm:MovieClip;
      
      public var kj22atm:MovieClip;
      
      public var kj2atm:MovieClip;
      
      public var kj2mc:MovieClip;
      
      public var kj2mc2:MovieClip;
      
      public var sbsmc:MovieClip;
      
      public var sh12atm:MovieClip;
      
      public var sh1atm:MovieClip;
      
      public var sh21atm:MovieClip;
      
      public var sh22atm:MovieClip;
      
      public var sh2atm:MovieClip;
      
      public var tkatm:MovieClip;
      
      public var tzatm:MovieClip;
      
      public var zh1atm:MovieClip;
      
      public var zh2atm:MovieClip;
      
      public var zh32atm:MovieClip;
      
      public var zh3atm:MovieClip;
      
      public function mc_0004_1()
      {
         super();
         addFrameScript(13,this.frame14,21,this.frame22,23,this.frame24,34,this.frame35,43,this.frame44,48,this.frame49,78,this.frame79,84,this.frame85,86,this.frame87,91,this.frame92,95,this.frame96,101,this.frame102,103,this.frame104,111,this.frame112,113,this.frame114,118,this.frame119,122,this.frame123,124,this.frame125,126,this.frame127,132,this.frame133,138,this.frame139,140,this.frame141,141,this.frame142,146,this.frame147,147,this.frame148,152,this.frame153,155,this.frame156,159,this.frame160,161,this.frame162,170,this.frame171,177,this.frame178,184,this.frame185,188,this.frame189,192,this.frame193,196,this.frame197,204,this.frame205,209,this.frame210,214,this.frame215,226,this.frame227,244,this.frame245,245,this.frame246,248,this.frame249,266,this.frame267,283,this.frame284,286,this.frame287,288,this.frame289,295,this.frame296,300,this.frame301,305,this.frame306,320,this.frame321,341,this.frame342,347,this.frame348,350,this.frame351,359,this.frame360,365,this.frame366,370,this.frame371,384
         ,this.frame385,400,this.frame401,430,this.frame431,434,this.frame435,435,this.frame436,443,this.frame444,446,this.frame447,450,this.frame451,460,this.frame461,464,this.frame465,479,this.frame480,490,this.frame491,505,this.frame506,528,this.frame529,543,this.frame544,554,this.frame555,577,this.frame578,588,this.frame589,589,this.frame590,591,this.frame592,618,this.frame619,622,this.frame623,633,this.frame634,643,this.frame644,657,this.frame658,726,this.frame727,729,this.frame730,764,this.frame765,781,this.frame782,849,this.frame850,850,this.frame851,856,this.frame857,859,this.frame860,875,this.frame876,901,this.frame902,913,this.frame914,917,this.frame918,934,this.frame935,1007,this.frame1008,1012,this.frame1013,1032,this.frame1033,1105,this.frame1106,1114,this.frame1115,1135,this.frame1136,1142,this.frame1143,1164,this.frame1165,1279,this.frame1280);
      }
      
      internal function frame14() : *
      {
         parent.$effect_ctrler.walk();
      }
      
      internal function frame22() : *
      {
         parent.$effect_ctrler.walk();
      }
      
      internal function frame24() : *
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
         parent.$effect_ctrler.shadow(255,0,0);
      }
      
      internal function frame44() : *
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
      
      internal function frame85() : *
      {
         parent.$mc_ctrler.setAirMove(true);
      }
      
      internal function frame87() : *
      {
         parent.$effect_ctrler.playSoundHit1();
      }
      
      internal function frame92() : *
      {
         parent.$mc_ctrler.setSkillAIR();
      }
      
      internal function frame96() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame102() : *
      {
         parent.$mc_ctrler.addQi(5);
         parent.$mc_ctrler.setTouchFloor("跳招_TF",true);
         parent.$mc_ctrler.isApplyG(true);
         parent.$mc_ctrler.movePercent(-0.5,-0.5);
         parent.$effect_ctrler.shadow(255,0,0);
         parent.$effect_ctrler.shine();
      }
      
      internal function frame104() : *
      {
         parent.$mc_ctrler.movePercent(2,1.5);
      }
      
      internal function frame112() : *
      {
         parent.$mc_ctrler.loop("跳招_L");
      }
      
      internal function frame114() : *
      {
         parent.$mc_ctrler.endAct();
         parent.$effect_ctrler.endShadow();
      }
      
      internal function frame119() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame123() : *
      {
         parent.$mc_ctrler.movePercent(0.25,0);
      }
      
      internal function frame125() : *
      {
         parent.$effect_ctrler.playSoundHit1();
      }
      
      internal function frame127() : *
      {
         parent.$mc_ctrler.setAttack("砍2");
         parent.$mc_ctrler.setZhao1();
         parent.$mc_ctrler.setBisha();
         parent.$mc_ctrler.stopMove();
      }
      
      internal function frame133() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame139() : *
      {
      }
      
      internal function frame141() : *
      {
         parent.$mc_ctrler.movePercent(0.5,0);
      }
      
      internal function frame142() : *
      {
         parent.$effect_ctrler.playSoundHit1();
      }
      
      internal function frame147() : *
      {
         parent.$mc_ctrler.setBisha();
         parent.$mc_ctrler.setSkill2();
         parent.$mc_ctrler.setAttack("砍3");
         parent.$mc_ctrler.setZhao1();
      }
      
      internal function frame148() : *
      {
         parent.$mc_ctrler.stopMove();
      }
      
      internal function frame153() : *
      {
         parent.$mc_ctrler.endAct();
      }
      
      internal function frame156() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame160() : *
      {
         parent.$effect_ctrler.playSoundHit2();
      }
      
      internal function frame162() : *
      {
         parent.$mc_ctrler.movePercent(1.3,0);
         parent.$mc_ctrler.dampingPercent(0.1,0);
      }
      
      internal function frame171() : *
      {
         parent.$mc_ctrler.setBishaSUPER();
         parent.$mc_ctrler.setSkill1();
         parent.$mc_ctrler.setAttack("砍4");
         parent.$mc_ctrler.setZhao2();
      }
      
      internal function frame178() : *
      {
         parent.$mc_ctrler.endAct();
      }
      
      internal function frame185() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame189() : *
      {
         parent.$mc_ctrler.movePercent(1,0);
      }
      
      internal function frame193() : *
      {
         parent.$effect_ctrler.playSoundHit2();
      }
      
      internal function frame197() : *
      {
         parent.$mc_ctrler.setBishaUP();
         parent.$mc_ctrler.setZhao3();
         parent.$mc_ctrler.setDash();
         parent.$mc_ctrler.stopMove();
      }
      
      internal function frame205() : *
      {
         parent.$mc_ctrler.endAct();
      }
      
      internal function frame210() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame215() : *
      {
         parent.$mc_ctrler.addQi(10);
      }
      
      internal function frame227() : *
      {
         parent.$mc_ctrler.setHitTarget("kj1_chkm","砍技1_CHK");
         parent.$mc_ctrler.movePercent(1.5,0);
         parent.$mc_ctrler.setSteelBody(true);
         parent.$effect_ctrler.shadow(255,0,0);
         parent.$effect_ctrler.dash();
      }
      
      internal function frame245() : *
      {
         parent.$mc_ctrler.dampingPercent(0.2,0);
         parent.$effect_ctrler.endShadow();
         parent.$effect_ctrler.shine();
         parent.$effect_ctrler.playSoundHit2();
      }
      
      internal function frame246() : *
      {
         parent.$mc_ctrler.setSteelBody(false);
      }
      
      internal function frame249() : *
      {
         parent.$mc_ctrler.endAct();
      }
      
      internal function frame267() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame284() : *
      {
         parent.$mc_ctrler.addQi(5);
      }
      
      internal function frame287() : *
      {
         parent.$mc_ctrler.movePercent(0.5,0);
      }
      
      internal function frame289() : *
      {
         parent.$effect_ctrler.playSoundHit1();
      }
      
      internal function frame296() : *
      {
         parent.$mc_ctrler.dampingPercent(0.1,0);
         parent.$effect_ctrler.playSoundHit1();
      }
      
      internal function frame301() : *
      {
         parent.$mc_ctrler.addAttacker("kj2mc");
      }
      
      internal function frame306() : *
      {
         parent.$mc_ctrler.addAttacker("kj2mc2");
      }
      
      internal function frame321() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame342() : *
      {
         parent.$mc_ctrler.addQi(5);
      }
      
      internal function frame348() : *
      {
         parent.$effect_ctrler.shine();
         parent.$mc_ctrler.fire("zh1atm",{
            "x":{
               "start":15,
               "hit":3
            },
            "hold":1,
            "hits":3
         });
      }
      
      internal function frame351() : *
      {
         parent.$mc_ctrler.setBisha();
         parent.$mc_ctrler.setZhao2();
      }
      
      internal function frame360() : *
      {
         parent.$mc_ctrler.endAct();
      }
      
      internal function frame366() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame371() : *
      {
         parent.$mc_ctrler.addQi(10);
      }
      
      internal function frame385() : *
      {
         parent.$effect_ctrler.shine();
         parent.$mc_ctrler.fire("zh2atm",{
            "x":{
               "start":10,
               "hit":5
            },
            "hold":1.5,
            "hits":5,
            "hp":200
         });
      }
      
      internal function frame401() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame431() : *
      {
         parent.$mc_ctrler.addQi(5);
         parent.$mc_ctrler.setSteelBody(true);
      }
      
      internal function frame435() : *
      {
         parent.$effect_ctrler.playSoundHit1();
      }
      
      internal function frame436() : *
      {
         parent.$mc_ctrler.setSteelBody(false);
         parent.$mc_ctrler.movePercent(2,-2.4);
         parent.$mc_ctrler.dampingPercent(0.05,0.1);
         parent.$effect_ctrler.shadow(255,0,0);
      }
      
      internal function frame444() : *
      {
         parent.$effect_ctrler.playSoundHit2();
      }
      
      internal function frame447() : *
      {
         parent.$mc_ctrler.endAct();
         parent.$effect_ctrler.endShadow();
      }
      
      internal function frame451() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame461() : *
      {
         parent.$mc_ctrler.addQi(10);
      }
      
      internal function frame465() : *
      {
         parent.$effect_ctrler.playSoundHit2();
      }
      
      internal function frame480() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame491() : *
      {
         parent.$mc_ctrler.addQi(20);
      }
      
      internal function frame506() : *
      {
         parent.$effect_ctrler.playSoundHit2();
      }
      
      internal function frame529() : *
      {
         parent.$mc_ctrler.endAct();
      }
      
      internal function frame544() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame555() : *
      {
         parent.$effect_ctrler.bisha(false,"Naruto_2");
      }
      
      internal function frame578() : *
      {
         parent.$mc_ctrler.movePercent(1,0);
         parent.$effect_ctrler.endBisha();
      }
      
      internal function frame589() : *
      {
         if(!parent.$fighter_ctrler.justHit("bs1"))
         {
            parent.$mc_ctrler.gotoAndPlay("必杀_0");
         }
      }
      
      internal function frame590() : *
      {
         parent.$mc_ctrler.dampingPercent(0.2,0);
      }
      
      internal function frame592() : *
      {
         parent.$effect_ctrler.shine(303095);
      }
      
      internal function frame619() : *
      {
         parent.$effect_ctrler.shine();
      }
      
      internal function frame623() : *
      {
         parent.$mc_ctrler.endAct();
      }
      
      internal function frame634() : *
      {
         parent.$mc_ctrler.endAct();
         parent.$mc_ctrler.dampingPercent(0.2,0);
      }
      
      internal function frame644() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame658() : *
      {
         parent.$effect_ctrler.bisha(false,"Naruto_1");
      }
      
      internal function frame727() : *
      {
         parent.$effect_ctrler.endBisha();
      }
      
      internal function frame730() : *
      {
         parent.$effect_ctrler.shine();
         parent.$mc_ctrler.addAttacker("sbsmc",{
            "x":{
               "moveToTarget":true,
               "offset":0
            },
            "y":{
               "moveToTarget":false,
               "offset":0
            },
            "applyG":true
         });
      }
      
      internal function frame765() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame782() : *
      {
         parent.$effect_ctrler.bisha(true,"Naruto_2");
      }
      
      internal function frame850() : *
      {
         parent.$effect_ctrler.endBisha();
      }
      
      internal function frame851() : *
      {
         parent.$effect_ctrler.dash();
      }
      
      internal function frame857() : *
      {
         parent.$fighter_ctrler.moveToTarget(0,null,false);
      }
      
      internal function frame860() : *
      {
         parent.$effect_ctrler.playSoundHit2();
      }
      
      internal function frame876() : *
      {
         parent.$effect_ctrler.playSoundHit2();
      }
      
      internal function frame902() : *
      {
         parent.$mc_ctrler.movePercent(0,1);
         parent.$mc_ctrler.setTouchFloor("超必杀_TF",true);
         parent.$fighter_ctrler.moveOnce(0,-150);
         parent.$effect_ctrler.shine();
         parent.$effect_ctrler.shine();
      }
      
      internal function frame914() : *
      {
         parent.$mc_ctrler.loop("超必杀_L");
      }
      
      internal function frame918() : *
      {
         parent.$effect_ctrler.shine();
         parent.$effect_ctrler.shake(0,5);
         parent.$mc_ctrler.addAttacker("cbsmc",{"applyG":false});
      }
      
      internal function frame935() : *
      {
         parent.$mc_ctrler.hurtFly(-15,-5);
      }
      
      internal function frame1008() : *
      {
         parent.$mc_ctrler.movePercent(0.5,0);
      }
      
      internal function frame1013() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame1033() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame1106() : *
      {
         parent.$mc_ctrler.idle();
      }
      
      internal function frame1115() : *
      {
         parent.$mc_ctrler.stop();
      }
      
      internal function frame1136() : *
      {
         parent.$mc_ctrler.stop();
      }
      
      internal function frame1143() : *
      {
         parent.$effect_ctrler.startWanKai("Naruto_3");
      }
      
      internal function frame1165() : *
      {
         parent.$effect_ctrler.shine(16776960);
         parent.$effect_ctrler.startShake(0,3);
      }
      
      internal function frame1280() : *
      {
         parent.$fighter_ctrler.addHpLosePercent(0.2);
         parent.$fighter_ctrler.doWanKai();
      }
   }
}

