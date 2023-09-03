package backend;

import flixel.util.FlxGradient;

class CustomFadeTransition extends MusicBeatSubstate {
	public static var finishCallback:Void->Void;
	private var leTween:FlxTween = null;
	public static var nextCamera:FlxCamera;
	var isTransIn:Bool = false;
	var transBlack:FlxSprite;
	var transGradient:FlxSprite;
	var loadImage:FlxSprite;
	var loadText:FlxText;


	public function new(duration:Float, isTransIn:Bool) {
		super();

		this.isTransIn = isTransIn;
		var zoom:Float = FlxMath.bound(FlxG.camera.zoom, 0.05, 1);
		var width:Int = Std.int(FlxG.width / zoom);
		var height:Int = Std.int(FlxG.height / zoom);
		
		loadImage = new FlxSprite(0, 0).loadGraphic(Paths.image('menus/loadingScreen' + FlxG.random.int(1, 2)) );
		add(loadImage);
		
		if (isTransIn) {
			loadImage.scale.x = 1.5;
			loadImage.scale.y = 1.5;
			alpha = 0;
		} else {
			loadImage.scale.x = 1;
			loadImage.scale.y = 1;
			alpha = 1;
		}
		
		loadText = new FlxText(0, 0, FlxG.width, 'Loading... \nPlease wait', 50);
		loadText.setFormat(Paths.font('vcr.ttf'), 50, FlxColor.WHITE, CENTER);
		add(loadText);
		if (isTransIn) loadText.alpha = 0;
		else loadText.alpha = 1;
		loadText.screenCenter();
		loadText.x -= 300;
		
		if(isTransIn) {
			FlxTween.tween(loadImage.scale, {x: 1, y: 1}, 0.3, {
				onComplete: function(twn:FlxTween) {
					close();
				},
			ease: FlxEase.circOut});
			
			FlxTween.tween(loadImage, {alpha: 1}, 0.3, {
				onComplete: function(twn:FlxTween) {
					close();
				},
			ease: FlxEase.circOut});
			
			FlxTween.tween(loadText, {alpha: 1}, 0.3, {
				onComplete: function(twn:FlxTween) {
					close();
				},
			ease: FlxEase.circOut});
		} else {
			leTween = FlxTween.tween(loadImage.scale, {x: 1.5, y: 1.5}, 0.3, {
				onComplete: function(twn:FlxTween) {
					if(finishCallback != null) {
						finishCallback();
					}
				},
			ease: FlxEase.circIn});
			
			leTween = FlxTween.tween(loadImage, {alpha: 0}, 0.3, {
				onComplete: function(twn:FlxTween) {
					if(finishCallback != null) {
						finishCallback();
					}
				},
			ease: FlxEase.circIn});
			
			leTween = FlxTween.tween(loadText, {alpha: 0}, 0.3, {
				onComplete: function(twn:FlxTween) {
					if(finishCallback != null) {
						finishCallback();
					}
				},
			ease: FlxEase.circIn});
		}

		if(nextCamera != null) {
			loadImage.cameras = [nextCamera];
		}
		nextCamera = null;
	}

	override function update(elapsed:Float) {
		//
	}

	override function destroy() {
		if(leTween != null) {
			finishCallback();
			leTween.cancel();
		}
		super.destroy();
	}
}