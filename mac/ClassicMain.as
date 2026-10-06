package {
    import flash.display.DisplayObject;
    import flash.display.DisplayObjectContainer;
    import flash.display.Loader;
    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.desktop.NativeApplication;
    import flash.events.Event;
    import flash.events.DataEvent;
    import flash.events.IOErrorEvent;
    import flash.events.InvokeEvent;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.events.SecurityErrorEvent;
    import flash.events.TimerEvent;
    import flash.events.UncaughtErrorEvent;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.net.URLRequest;
    import flash.net.SharedObject;
    import flash.system.ApplicationDomain;
    import flash.system.LoaderContext;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.utils.Timer;
    import flash.utils.getQualifiedClassName;

    /** Mac entry point for the unmodified official OpenBVN 3.4 release. */
    [SWF(width="800", height="600", frameRate="30", backgroundColor="#000000")]
    public class ClassicMain extends Sprite {
        private var loader:Loader = new Loader();
        private var readyTimer:Timer = new Timer(50, 600);
        private var domain:ApplicationDomain;
        private var status:TextField = new TextField();
        private var gameData:Object;
        private var settings:SharedObject;
        private var diagnosticStream:FileStream;

        public function ClassicMain() {
            NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, invoked);
            if (stage) initialize();
            else addEventListener(Event.ADDED_TO_STAGE, initialize);
        }

        private function invoked(event:InvokeEvent):void {
            if (event.arguments.indexOf("--diagnostics") < 0 || diagnosticStream) return;
            diagnosticStream = new FileStream();
            diagnosticStream.open(File.applicationStorageDirectory.resolvePath("classic-diagnostics.log"), FileMode.WRITE);
            stage.addEventListener(KeyboardEvent.KEY_DOWN, diagnosticKey, false, -100);
            stage.addEventListener(KeyboardEvent.KEY_UP, diagnosticKey, false, -100);
            stage.addEventListener(MouseEvent.CLICK, diagnosticClick);
            diagnostic("INPUT_DIAGNOSTICS_ENABLED");
        }

        private function diagnosticKey(event:KeyboardEvent):void {
            diagnostic(event.type + " keyCode=" + event.keyCode + " charCode=" + event.charCode);
            if (domain && gameData && event.type == KeyboardEvent.KEY_DOWN) {
                var Input:Class = definition("input.GameInputer");
                var Types:Class = definition("input.GameInputType");
                diagnostic("INPUT_STATE: enabled=" + Input["enabled"] + " attackKey=" + gameData.config.key_p1.attack
                    + " selectKeys=" + gameData.config.key_p1.selects + " selectDown=" + Input["select"](Types["P1"]));
            }
        }

        private function diagnosticClick(event:MouseEvent):void {
            var target:DisplayObject = event.target as DisplayObject;
            var path:String = "";
            while (target && target != stage) {
                path += target.name + "(" + getQualifiedClassName(target) + ")/";
                target = target.parent;
            }
            diagnostic("CLICK_TARGET: " + path);
            if (gameData) {
                var Select:Class = definition("stage.SelectFighterStage");
                diagnostic("SELECT_STATE: map=" + gameData.selectMap + " autoFinish=" + Select["AUTO_FINISH"]);
            }
        }

        private function diagnostic(message:String):void {
            trace(message);
            if (diagnosticStream) diagnosticStream.writeUTFBytes(message + "\n");
        }

        private function initialize(event:Event = null):void {
            removeEventListener(Event.ADDED_TO_STAGE, initialize);
            stage.scaleMode = StageScaleMode.NO_SCALE;
            // AIR descriptor dimensions include the macOS window title bar.
            stage.nativeWindow.width += 800 - stage.stageWidth;
            stage.nativeWindow.height += 600 - stage.stageHeight;
            stage.align = "";
            stage.addEventListener(Event.RESIZE, resizeViewport);
            status.defaultTextFormat = new TextFormat("_sans", 18, 0xffffff);
            status.width = 780;
            status.height = 150;
            status.x = 10;
            status.y = 240;
            status.wordWrap = true;
            status.text = "正在载入死神 vs 火影 3.4…";
            addChild(status);
            addChild(loader);
            loader.contentLoaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, uncaught);
            loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, uncaught);
            resizeViewport();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loaded);
            loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, loadFailed);
            loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, loadFailed);
            loader.load(new URLRequest(File.applicationDirectory.resolvePath("FighterTester.swf").url),
                new LoaderContext(false, new ApplicationDomain(ApplicationDomain.currentDomain)));
        }

        private function uncaught(event:UncaughtErrorEvent):void {
            var error:Error = event.error as Error;
            diagnostic("CLASSIC_RUNTIME_ERROR: " + (error ? (error.getStackTrace() || error.message) : event.error));
        }

        private function resizeViewport(event:Event = null):void {
            var scale:Number = Math.min(stage.stageWidth / 800, stage.stageHeight / 600);
            loader.scaleX = loader.scaleY = scale;
            loader.x = (stage.stageWidth - 800 * scale) / 2;
            loader.y = (stage.stageHeight - 600 * scale) / 2;
        }

        private function loaded(event:Event):void {
            domain = loader.contentLoaderInfo.applicationDomain;
            readyTimer.addEventListener(TimerEvent.TIMER, checkReady);
            readyTimer.addEventListener(TimerEvent.TIMER_COMPLETE, timedOut);
            readyTimer.start();
        }

        private function definition(name:String):Class {
            return domain.getDefinition("net.play5d.game.obvn." + name) as Class;
        }

        private function checkReady(event:TimerEvent):void {
            // The original tester adds its panel only after all UI/config assets finish loading.
            var original:DisplayObjectContainer = loader.content as DisplayObjectContainer;
            if (!original || original.numChildren < 2) return;
            readyTimer.stop();
            try {
                var Main:Class = definition("MainGame");
                var Data:Class = definition("data.GameData");
                var Config:Class = definition("vo.ConfigVO");
                var Input:Class = definition("input.GameInputer");
                var State:Class = definition("ctrler.StateCtrler");
                var Debug:Class = definition("Debugger");
                var game:Object = Main["I"];
                var data:Object = Data["I"];
                gameData = data;
                var selection:Object = data.config.select_config;

                // Undo tester-only double HP, unlimited time and highest AI difficulty.
                data.config = new Config();
                data.config.select_config = selection;
                data.loadData();
                settings = SharedObject.getLocal("bvn34-classic-settings");
                if (settings.data.config) {
                    // ConfigVO.readSaveObj deletes keys from its argument.
                    data.config.readSaveObj(JSON.parse(JSON.stringify(settings.data.config)));
                }
                data.config.applyConfig();
                Input["updateConfig"]();
                State["I"].transEnabled = true;
                Debug["onErrorMsgCall"] = reportGameError;

                while (original.numChildren > 1) original.removeChildAt(1);
                // Debugger attaches its FPS/mode labels directly to the Stage.
                for (var i:int = stage.numChildren - 1; i >= 0; i--) {
                    var child:DisplayObject = stage.getChildAt(i);
                    if (child != this) child.visible = false;
                }
                removeChild(status);
                resizeViewport();
                diagnostic("VIEWPORT: stage=" + stage.stageWidth + "x" + stage.stageHeight
                    + " rootClip=" + game.root.scrollRect + " loaderScale=" + loader.scaleX
                    + " originalClip=" + original.scrollRect + " originalMask=" + original.mask);
                stage.addEventListener("5d_message", gameMessage);
                stage.nativeWindow.addEventListener(Event.CLOSING, saveSettings);
                game.goLogo();
                diagnostic("CLASSIC_READY: original 3.4 logo/menu/character selection enabled");
            } catch (error:Error) {
                showFailure(error.getStackTrace() || error.message);
            }
        }

        private function reportGameError(message:String):void {
            if (message) diagnostic("CLASSIC_GAME_ERROR: " + message);
        }

        private function gameMessage(event:DataEvent):void {
            var message:Array = JSON.parse(event.data) as Array;
            diagnostic("CLASSIC_SCENE: " + event.data);
            if (message && message[0] == "go_menu_stage") saveSettings();
        }

        private function saveSettings(event:Event = null):void {
            if (!settings || !gameData) return;
            try {
                settings.data.config = gameData.config.toSaveObj();
                settings.flush();
                diagnostic("CLASSIC_SETTINGS_SAVED");
            } catch (error:Error) {
                diagnostic("CLASSIC_SETTINGS_ERROR: " + error.message);
            }
        }

        private function timedOut(event:TimerEvent):void {
            showFailure("游戏资源加载超时，请检查 assets 目录。\n可使用 run-mac.command 查看日志。");
        }

        private function loadFailed(event:Event):void {
            showFailure(event.toString());
        }

        private function showFailure(message:String):void {
            readyTimer.stop();
            diagnostic("CLASSIC_START_ERROR: " + message);
            if (!contains(status)) addChild(status);
            status.text = "启动失败：\n" + message;
        }
    }
}
