package backend;

import flixel.util.FlxGradient;

class CustomFadeTransition extends MusicBeatSubstate {
	public static var finishCallback:Void->Void;
	private var leTween:FlxTween = null;
	public static var nextCamera:FlxCamera;
	var isTransIn:Bool = false;
	var loadImage:FlxSprite;
	var loadText:FlxText;

	public function new(duration:Float, isTransIn:Bool) {
		super();

		this.isTransIn = isTransIn;
		
		loadImage = new FlxSprite(0, 0, Paths.image('menus/loadingScreen' + FlxG.random.int(1, 2)));
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
		
		loadText = new FlxText(0, 0, FlxG.width, 'Loading...\nPlease wait', 50);
		loadText.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, CENTER);
		add(loadText);
		loadText.alpha = (isTransIn ? 0 : 1);
		loadText.screenCenter();
		loadText.x -= 300;
		
		if(isTransIn) {
			FlxTween.tween(loadImage, {scale.x: 1, scale.y: 1, alpha: 1}, 0.3, {
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
			leTween = FlxTween.tween(loadImage, {scale.x: 1.5, scale.y: 1.5, alpha: 0}, 0.3, {
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

	override function destroy() {
		if(leTween != null) {
			finishCallback();
			leTween.cancel();
		}
		super.destroy();
	}
}