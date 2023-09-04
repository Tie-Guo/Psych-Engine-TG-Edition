package backend;

import flixel.util.FlxGradient;
import states.TitleState;

class CustomFadeTransition extends MusicBeatSubstate {
	public static var finishCallback:Void->Void;
	private var leTween:FlxTween = null;
	public static var nextCamera:FlxCamera;
	var isTransIn:Bool = false;
	var loadBG:FlxSprite;
	var loadTX:FlxText;

	public function new(duration:Float, isTransIn:Bool) {
		super();

		this.isTransIn = isTransIn;
		var zoom:Float = FlxMath.bound(FlxG.camera.zoom, 0.05, 1);
		var width:Int = Std.int(FlxG.width / zoom);
		var height:Int = Std.int(FlxG.height / zoom);
		var timeduration:Float = 0.3;
		
		if (!TitleState.inGame) {
			loadBG = new FlxSprite().makeGraphic(1280, 720, FlxColor.BLACK);
		} else
			loadBG = new FlxSprite().loadGraphic(Paths.image('menus/loadingScreen' + FlxG.random.int(1, 2)));
		add(loadBG);
		
		loadTX = new FlxText(50, 200, 0, 'Loading... \nWait it...', 50);
		loadTX.setFormat(Paths.font('vcr.ttf'), 50, FlxColor.WHITE);
		add(loadTX);
		
		if (isTransIn) {
			loadBG.alpha = 0;
			loadBG.scale.x = 1.5;
			loadBG.scale.y = 1.5;
			loadTX.alpha = 0;
		} else {
			loadBG.alpha = 1;
			loadBG.scale.x = 1;
			loadBG.scale.y = 1;
			loadTX.alpha = 1;
		}

		if(isTransIn) {
			FlxTween.tween(loadBG, {alpha: 1}, timeduration, {
				onComplete: function(twn:FlxTween) {
					close();
				},
			ease: FlxEase.linear});
			
			FlxTween.tween(loadTX, {alpha: 1}, timeduration, {
				onComplete: function(twn:FlxTween) {
					close();
				},
			ease: FlxEase.linear});
		} else {
			leTween = FlxTween.tween(loadBG, {alpha: 0}, timeduration, {
				onComplete: function(twn:FlxTween) {
					if(finishCallback != null) {
						finishCallback();
					}
				},
			ease: FlxEase.linear});
			
			leTween = FlxTween.tween(loadTX, {alpha: 0}, timeduration, {
				onComplete: function(twn:FlxTween) {
					if(finishCallback != null) {
						finishCallback();
					}
				},
			ease: FlxEase.linear});
		}

		if(nextCamera != null) {
			loadBG.cameras = [nextCamera];
			loadTX.cameras = [nextCamera];
		}
		nextCamera = null;
	}

	override function destroy() {
		if(leTween != null) {
			finishCallback();
			leTween.cancel();
		}
		super.destroy();
	}
}