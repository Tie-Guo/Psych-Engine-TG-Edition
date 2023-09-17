package states;

import backend.WeekData;
import backend.Achievements;

import flixel.FlxObject;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;

import flixel.input.keyboard.FlxKey;
import lime.app.Application;

import objects.AchievementPopup;
import states.editors.MasterEditorMenu;
import options.OptionsState;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.7.1h'; //This is also used for Discord RPC
	public static var tgEngineVersion:String = '1.1.0';
	public static var curSelected:Int = 0;
	public static var curSelectedExtra:Int = 0;
	public static var inExtra:Bool = false;
	var inChanging:Bool = false;

	var menuItems:FlxTypedGroup<FlxSprite>;
	var menuItemsExtra:FlxTypedGroup<FlxSprite>;
	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;
	
	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',
		'options',
		'extra'
	];
	
	var optionShitExtra:Array<String> = [
		#if ACHIEVEMENTS_ALLOWED 'awards', #end
		#if MODS_ALLOWED 'mods', #end
		'credits',
		#if !switch 'donate', #end
		'back'
	];

	var magenta:FlxSprite;
	var camFollow:FlxObject;

	override function create()
	{
		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement, false);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.antialiasing = ClientPrefs.data.antialiasing;
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.color = 0xFFfd719b;
		add(magenta);
		
		// magenta.scrollFactor.set();

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);
		
		menuItemsExtra = new FlxTypedGroup<FlxSprite>();
		add(menuItemsExtra);
		
		var array:Array<String> = [];
		if(Mods.mergeAllTextsNamed('images/mainmenu/list_normal.txt', 'shared').length > 0)
			array = Mods.mergeAllTextsNamed('images/mainmenu/list_normal.txt', 'shared');
		else
			array = CoolUtil.coolTextFile(Paths.getPreloadPath('shared/images/mainmenu/list_normal.txt'));
		
		if (array.length > 0) optionShit = array;
		
		if(Mods.mergeAllTextsNamed('images/mainmenu/list_extra.txt', 'shared').length > 0)
			array = Mods.mergeAllTextsNamed('images/mainmenu/list_extra.txt', 'shared');
		else
			array = CoolUtil.coolTextFile(Paths.getPreloadPath('shared/images/mainmenu/list_extra.txt'));
		
		if (array.length > 0) optionShitExtra = array;

		var scale:Float = 1;
		/*if(optionShit.length > 6) {
			scale = 6 / optionShit.length;
		}*/
		
		for (i in 0...optionShitExtra.length)
		{
			var offset:Float = 108 - (Math.max(optionShitExtra.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite(0, (i * 140)  + offset);
			menuItem.antialiasing = ClientPrefs.data.antialiasing;
			menuItem.scale.x = scale;
			menuItem.scale.y = scale;
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShitExtra[i]);
			menuItem.animation.addByPrefix('idle', optionShitExtra[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShitExtra[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItem.screenCenter(X);
			if (!inExtra) menuItem.x += 1000;
			menuItemsExtra.add(menuItem);
			var scr:Float = (optionShitExtra.length - 4) * 0.135;
			if(optionShitExtra.length < 6) scr = 0;
			menuItem.scrollFactor.set(0, scr);
			//menuItem.setGraphicSize(Std.int(menuItem.width * 0.58));
			menuItem.updateHitbox();
		}

		for (i in 0...optionShit.length)
		{
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite(0, (i * 140)  + offset);
			menuItem.antialiasing = ClientPrefs.data.antialiasing;
			menuItem.scale.x = scale;
			menuItem.scale.y = scale;
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItem.screenCenter(X);
			if (inExtra) menuItem.x -= 1000;
			menuItems.add(menuItem);
			var scr:Float = (optionShit.length - 4) * 0.135;
			if(optionShit.length < 6) scr = 0;
			menuItem.scrollFactor.set(0, scr);
			//menuItem.setGraphicSize(Std.int(menuItem.width * 0.58));
			menuItem.updateHitbox();
		}

		FlxG.camera.follow(camFollow, null, 0);
		
		
		var versionShit:FlxText = new FlxText(12, FlxG.height - 64, 0, "TG Edition v" + tgEngineVersion, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);
		var versionShit:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);
		var versionShit:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		// NG.core.calls.event.logEvent('swag').send();

		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		Achievements.loadAchievements();
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18) {
			var achieveID:Int = Achievements.getAchievementIndex('friday_night_play');
			if(!Achievements.isAchievementUnlocked(Achievements.achievementsStuff[achieveID][2])) { //It's a friday night. WEEEEEEEEEEEEEEEEEE
				Achievements.achievementsMap.set(Achievements.achievementsStuff[achieveID][2], true);
				giveAchievement();
				ClientPrefs.saveSettings();
			}
		}
		#end
		
		#if android
		addVirtualPad(UP_DOWN, A_B_E);
		#end

		super.create();
	}

	#if ACHIEVEMENTS_ALLOWED
	// Unlocks "Freaky on a Friday Night" achievement
	function giveAchievement() {
		add(new AchievementPopup('friday_night_play', camAchievement));
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		trace('Giving achievement "friday_night_play"');
	}
	#end

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * elapsed;
			if(FreeplayState.vocals != null) FreeplayState.vocals.volume += 0.5 * elapsed;
		}
		FlxG.camera.followLerp = FlxMath.bound(elapsed * 9 / (FlxG.updateFramerate / 60), 0, 1);

		if (!selectedSomethin && !inChanging)
		{
			if (controls.UI_UP_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.UI_DOWN_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
				openSelected();
			}
			#if (desktop || android)
			else if (controls.justPressed('debug_1') #if android || MusicBeatState._virtualpad.buttonE.justPressed #end)
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		super.update(elapsed);
	}
	
	function openSelected()
	{
		var daChoice:String = '';
		if (inExtra) daChoice = optionShitExtra[curSelectedExtra];
		else daChoice = optionShit[curSelected];
		
		if (daChoice == 'extra' && !inChanging) {
			inChanging = true;
			FlxG.sound.play(Paths.sound('confirmMenu'));
			doTweenG(0.6);
		} else if (daChoice == 'back' && !inChanging) {
			inChanging = true;
			FlxG.sound.play(Paths.sound('confirmMenu'));
			doTweenG(0.6);
		} else if (daChoice == 'donate') {
			CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
		} else {
			selectedSomethin = true;
			FlxG.sound.play(Paths.sound('confirmMenu'));

			if(ClientPrefs.data.flashing) FlxFlicker.flicker(magenta, 1.1, 0.15, false);
			
			var menuItemss = new FlxTypedGroup<FlxSprite>();
			add(menuItemss);
			
			if (inExtra) menuItemss = menuItemsExtra;
			else menuItemss = menuItems;
			
			menuItemss.forEach(function(spr:FlxSprite) {
				if (curSelected != spr.ID) {
					FlxTween.tween(spr, {alpha: 0}, 0.4, {
						ease: FlxEase.quadOut,
						onComplete: function(twn:FlxTween)
						{
							spr.kill();
						}
					});
				} else {
					FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker) {

						switch (daChoice) {
							case 'story_mode':
								MusicBeatState.switchState(new StoryMenuState());
							case 'freeplay':
								MusicBeatState.switchState(new FreeplayState());
							case 'options':
								LoadingState.loadAndSwitchState(new OptionsState());
								OptionsState.onPlayState = false;
								if (PlayState.SONG != null)
								{
									PlayState.SONG.arrowSkin = null;
									PlayState.SONG.splashSkin = null;
								}
							#if MODS_ALLOWED
							case 'mods':
								MusicBeatState.switchState(new ModsMenuState());
							#end
							case 'awards':
								MusicBeatState.switchState(new AchievementsMenuState());
							case 'credits':
								MusicBeatState.switchState(new CreditsState());
							}
					});
				}
			});
		}
	}
	
	function doTweenG(time:Float)
	{
		if (inExtra) {
			menuItemsExtra.forEach(function(spr:FlxSprite) {
				FlxTween.tween(spr, {x: spr.x + 1000}, time, {
					ease: FlxEase.backInOut, onComplete: function(twn:FlxTween)
					{
						inChanging = false;
					}
				});
			});
			
			menuItems.forEach(function(spr:FlxSprite) {
				FlxTween.tween(spr, {x: spr.x + 1000}, time, {ease: FlxEase.backInOut});
			});
		} else {
			menuItems.forEach(function(spr:FlxSprite) {
				FlxTween.tween(spr, {x: spr.x - 1000}, time, {
					ease: FlxEase.backInOut, onComplete: function(twn:FlxTween)
					{
						inChanging = false;
					}
				});
			});
			
			menuItemsExtra.forEach(function(spr:FlxSprite) {
				FlxTween.tween(spr, {x: spr.x - 1000}, time, {ease: FlxEase.backInOut});
			});
		}
		inExtra = !inExtra;
		changeItem();
	}

	function changeItem(huh:Int = 0)
	{
		if (inExtra)
		{
    		curSelectedExtra += huh;
    
    		if (curSelectedExtra >= menuItemsExtra.length)
    			curSelectedExtra = 0;
    		if (curSelectedExtra < 0)
    			curSelectedExtra = menuItemsExtra.length - 1;
    
    		menuItemsExtra.forEach(function(spr:FlxSprite)
    		{
    			spr.animation.play('idle');
    			spr.updateHitbox();
    
    			if (spr.ID == curSelectedExtra)
    			{
    				spr.animation.play('selected');
    				var add:Float = 0;
    				if(menuItemsExtra.length > 4) {
    					add = menuItemsExtra.length * 8;
    				}
    				camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y - add);
    				spr.centerOffsets();
    			}
    		});
		} else {
			curSelected += huh;
    
    		if (curSelected >= menuItems.length)
    			curSelected = 0;
    		if (curSelected < 0)
    			curSelected = menuItems.length - 1;
    
    		menuItems.forEach(function(spr:FlxSprite)
    		{
    			spr.animation.play('idle');
    			spr.updateHitbox();
    
    			if (spr.ID == curSelected)
    			{
    				spr.animation.play('selected');
    				var add:Float = 0;
    				if(menuItems.length > 4) {
    					add = menuItems.length * 8;
    				}
    				camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y - add);
    				spr.centerOffsets();
    			}
    		});
		}
	}
}
