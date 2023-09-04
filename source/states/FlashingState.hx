package states;

import flixel.FlxSubState;

import flixel.effects.FlxFlicker;
import lime.app.Application;
import flixel.addons.transition.FlxTransitionableState;

class FlashingState extends MusicBeatState
{
	public static var leftState:Bool = false;
	var inLanguage:Bool = true;
	var curLanguage:Int = 0;
	var canExit:Bool = false;
	var langList:Array<String> = [];

	var warnText:FlxText;
	var languText:FlxText;
	var languChText:FlxText;
	override function create()
	{
		super.create();
		langList = Language.languages;

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);
		
		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(bg);

		languText = new FlxText(0, 200, FlxG.width, 'Choose Your Language', 50);
		languText.setFormat(Paths.font('vcr.ttf'), 50, FlxColor.WHITE, CENTER);
		languText.screenCenter(X);
		add(languText);
		
		languChText = new FlxText(0, 350, FlxG.width, '', 36);
		languChText.setFormat(Paths.font('vcr.ttf'), 36, FlxColor.WHITE, CENTER);
		languChText.screenCenter(X);
		add(languChText);
		
		languChText.text = '< ' + Language.defaultLanguage + ' >';
		
		#if android
			addVirtualPad(LEFT_RIGHT, A_B);
		#end
	}

	override function update(elapsed:Float)
	{
		if (inLanguage) {
			if (controls.UI_RIGHT_P) {
				changeLanguage(1);
			}
			
			if (controls.UI_LEFT_P) {
				changeLanguage(-1);
			}
			
			if (controls.ACCEPT) {
				FlxG.sound.play(Paths.sound('confirmMenu'));
				inLanguage = false;
				FlxTween.tween(languChText, {alpha: 0}, 0.4, {onComplete: function(twn:FlxTween)
					{
						event();
					}
				});
				FlxTween.tween(languText, {alpha: 0}, 0.4);
			}
		} else {
			if(!leftState) {
				var back:Bool = controls.BACK;
				if ((controls.ACCEPT || back) && canExit) {
					leftState = true;
					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;
					if(!back) {
						ClientPrefs.data.flashing = true;
						ClientPrefs.saveSettings();
						FlxG.sound.play(Paths.sound('confirmMenu'));
						FlxFlicker.flicker(warnText, 1, 0.1, false, true, function(flk:FlxFlicker) {
							new FlxTimer().start(0.5, function (tmr:FlxTimer) {
								MusicBeatState.switchState(new TitleState());
							});
						});
					} else {
						ClientPrefs.data.flashing = false;
						ClientPrefs.saveSettings();
						FlxG.sound.play(Paths.sound('cancelMenu'));
						FlxTween.tween(warnText, {alpha: 0}, 1, {
							onComplete: function (twn:FlxTween) {
								MusicBeatState.switchState(new TitleState());
							}
						});
					}
				}
			}
		}
		super.update(elapsed);
	}
	
	function changeLanguage(intt:Int = 0)
	{
		curLanguage += intt;
		if (curLanguage > langList.length-1)
			curLanguage = 0;
		if (curLanguage < 0)
			curLanguage = langList.length-1;
		
		languChText.text = '< ' + langList[curLanguage] + ' >';
		ClientPrefs.data.language = langList[curLanguage];
		ClientPrefs.saveSettings();
	}
	
	function event()
	{
		if (Language.get() == 'English') {
		warnText = new FlxText(0, 0, FlxG.width,
			"Hey, watch out!\n
			This Mod contains some flashing lights!\n
			Press " +  #if android "A" #else "ENTER" #end + " to disable them now or go to Options Menu.\n
			Press " +  #if android "B" #else "ESCAPE" #end + " to ignore this message.\n
			You've been warned!",
			32);
		} else {
		warnText = new FlxText(0, 0, FlxG.width,
			"注意!\n
			部分模组中可能出现闪光特效!\n
			按下 " +  #if android "A" #else "ENTER" #end + " 现在来关闭闪光特效, 或前往设置.\n
			按下 " +  #if android "B" #else "ESCAPE" #end + " 忽略此信息.\n
			你已经被警告过了!",
			32);
		}
		warnText.setFormat(Language.font(), 32, FlxColor.WHITE, CENTER);
		warnText.screenCenter(Y);
		add(warnText);
		warnText.alpha = 0;
		FlxTween.tween(warnText, {alpha: 1}, 0.4, {onComplete: 
		function(twn:FlxTween) {
				canExit = true;
			}
		});
		
		#if android
			removeVirtualPad();
			addVirtualPad(NONE, A_B);
		#end
	}
}
