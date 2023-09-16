package states;

import backend.Achievements;
import objects.AttachedAchievement;

class AchievementsMenuState extends MusicBeatState
{
	#if ACHIEVEMENTS_ALLOWED
	var options:Array<String> = [];
	private var grpOptions:FlxTypedGroup<Alphabet>;
	private static var curSelected:Int = 0;
	private var achievementArray:Array<AttachedAchievement> = [];
	private var achievementIndex:Array<Int> = [];
	private var textArray:Array<Alphabet> = [];
	private var descText:FlxText;
	private var nameText:FlxText;
	var descBox:FlxSprite;

	override function create() {
		#if desktop
		DiscordClient.changePresence("Achievements Menu", null);
		#end
		
		curSelected = 0;

		var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuBGBlue'));
		menuBG.antialiasing = ClientPrefs.data.antialiasing;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		add(menuBG);
		
		descBox = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		descBox.alpha = 0.6;
		add(descBox);

		Achievements.loadAchievements();
		for (i in 0...Achievements.achievementsStuff.length) {
			if(!Achievements.achievementsStuff[i][3] || Achievements.achievementsMap.exists(Achievements.achievementsStuff[i][2])) {
				options.push(Achievements.achievementsStuff[i]);
				achievementIndex.push(i);
			}
		}

		for (i in 0...options.length) {
			var achieveName:String = Achievements.achievementsStuff[achievementIndex[i]][2];
			var icon:AttachedAchievement = new AttachedAchievement(105, 200, achieveName);
			icon.scale.set(1.2, 1.2);
			icon.updateHitbox();
			icon.screenCenter(X);
			icon.x += i*(63 + 180);
			achievementArray.push(icon);
			add(icon);
		}
		
		nameText = new FlxText(150, 520, 980, "?", 35);
		nameText.setFormat(Paths.font("vcr.ttf"), 35, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		nameText.scrollFactor.set();
		nameText.borderSize = 2.4;
		add(nameText);

		descText = new FlxText(150, 600, 980, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2.4;
		add(descText);
		
		changeSelection();
		
		#if android
			addVirtualPad(LEFT_RIGHT, B);
		#end

		super.create();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (controls.UI_LEFT_P) {
			changeSelection(-1);
		}
		if (controls.UI_RIGHT_P) {
			changeSelection(1);
		}
		
		for (i in 0...achievementArray.length) {
			achievementArray[i].x = FlxMath.lerp( (FlxG.width - 180)/2 + (i-curSelected)*(63 + 180), achievementArray[i].x, FlxMath.bound(1 - (elapsed * 9.5), 0, 1));
			
			if (i != curSelected) {
				if (i <= curSelected - 2 || i >= curSelected + 2) {
					achievementArray[i].scale.x = FlxMath.lerp(0.8, achievementArray[i].scale.x, FlxMath.bound(1 - (elapsed * 8.5), 0, 1));
					achievementArray[i].scale.y = FlxMath.lerp(0.8, achievementArray[i].scale.y, FlxMath.bound(1 - (elapsed * 8.5), 0, 1));
				} else {
					achievementArray[i].scale.x = FlxMath.lerp(1, achievementArray[i].scale.x, FlxMath.bound(1 - (elapsed * 8.5), 0, 1));
					achievementArray[i].scale.y = FlxMath.lerp(1, achievementArray[i].scale.y, FlxMath.bound(1 - (elapsed * 8.5), 0, 1));
				}
			} else {
				achievementArray[i].scale.x = FlxMath.lerp(1.2, achievementArray[i].scale.x, FlxMath.bound(1 - (elapsed * 8.5), 0, 1));
				achievementArray[i].scale.y = FlxMath.lerp(1.2, achievementArray[i].scale.y, FlxMath.bound(1 - (elapsed * 8.5), 0, 1));
			}
		}

		if (controls.BACK) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}
	}

	function changeSelection(change:Int = 0) {
		curSelected += change;
		if (curSelected < 0)
			curSelected = options.length - 1;
		if (curSelected >= options.length)
			curSelected = 0;

		for (i in 0...achievementArray.length) {
			achievementArray[i].alpha = 0.6;
			if(i == curSelected) {
				achievementArray[i].alpha = 1;
			}
		}
		descText.text = Achievements.achievementsStuff[achievementIndex[curSelected]][1];
		
		descBox.setPosition(descText.x - 10, descText.y - 100);
		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25) + Std.int(nameText.height + 33));
		descBox.updateHitbox();
		
		var achieveName:String = Achievements.achievementsStuff[achievementIndex[curSelected]][2];
		var string:String = '?';
		if (Achievements.isAchievementUnlocked(achieveName)) 
			string = Achievements.achievementsStuff[achievementIndex[curSelected]][0];
			
		nameText.text = string;
		
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}
	#end
}
