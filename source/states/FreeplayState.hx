package states;

import backend.WeekData;
import backend.Highscore;
import backend.Song;
import backend.SongMetadata;

import lime.utils.Assets;
import openfl.utils.Assets as OpenFlAssets;

import objects.HealthIcon;
import states.editors.ChartingState;

import substates.GameplayChangersSubstate;
import substates.ResetScoreSubState;

import flixel.addons.ui.FlxInputText;
import flixel.addons.transition.FlxTransitionableState;

#if MODS_ALLOWED
import sys.FileSystem;
#end

class FreeplayState extends MusicBeatState
{
	var bg:FlxSprite;
    var songs:Array<SongMetadata> = [];
    var songtextsGroup:Array<FlxText> = [];
    var iconsArray:Array<HealthIcon> = [];
    var songtextsLastY:Array<Float> = [];
    
    var baseX:Float = 200;
    var lastMouseY:Float = 0;
    var curSelectedels:Float = 0;
    var curSelected:Int = 0;
    var curDifficulty:Int = 0;
    var intendedColor:Int;
    var touchMoving:Bool = false;
    
    var illustration:FlxSprite;
	var illustrationBG:FlxSprite;
	var illustrationOverlap:FlxSprite;
	var rightArrow:FlxSprite;
	var leftArrow:FlxSprite;
	var difficultieImage:FlxSprite;
	var difficultieText:FlxText;
    
    var changingYTween:FlxTween;
    var changingXTween:FlxTween;
    var colorTween:FlxTween;
    var angleTween:FlxTween;
	var angleTweenBG:FlxTween;
	var angleTweenOverlap:FlxTween;
    
	override function create()
	{
		//Paths.clearStoredMemory();
		//Paths.clearUnusedMemory();
		
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		
		songs = [];
		FlxG.mouse.visible = true;

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
    	bg.antialiasing = ClientPrefs.data.antialiasing;
    	add(bg);
    	intendedColor = bg.color;
    	bg.screenCenter();
    	
    	illustrationBG = new FlxSprite(780+20, 100+20).makeGraphic(425, 425, FlxColor.GRAY);
    	illustrationBG.antialiasing = ClientPrefs.data.antialiasing;
    	illustrationBG.updateHitbox();
    	add(illustrationBG);
    	
    	illustration = new FlxSprite(780, 100).loadGraphic(Paths.image('unknownMod'));
    	illustration.antialiasing = ClientPrefs.data.antialiasing;
    	illustration.scale.x = 425/illustration.width;
    	illustration.scale.y = 425/illustration.height;
    	illustration.updateHitbox();
    	add(illustration);
    	
    	illustrationOverlap = new FlxSprite(780, 100).makeGraphic(425, 425, FlxColor.WHITE);
    	illustrationOverlap.antialiasing = ClientPrefs.data.antialiasing;
    	illustrationOverlap.updateHitbox();
    	add(illustrationOverlap);
    	illustrationOverlap.alpha = 0;
    	
    	var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');
	
    	leftArrow = new FlxSprite(0, 615);
    	leftArrow.antialiasing = ClientPrefs.data.antialiasing;
    	leftArrow.frames = ui_tex;
    	leftArrow.animation.addByPrefix('idle', "arrow left");
    	leftArrow.animation.addByPrefix('press', "arrow push left");
    	leftArrow.animation.play('idle');
    	add(leftArrow);
    	
    	rightArrow = new FlxSprite(0, 615);
    	rightArrow.antialiasing = ClientPrefs.data.antialiasing;
    	rightArrow.frames = ui_tex;
    	rightArrow.animation.addByPrefix('idle', 'arrow right');
    	rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
    	rightArrow.animation.play('idle');
    	add(rightArrow);
    	
    	for (i in 0...WeekData.weeksList.length) {
    		if(weekIsLocked(WeekData.weeksList[i])) continue;
    
    		var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
    		var leSongs:Array<String> = [];
    		var leChars:Array<String> = [];
    
    		for (j in 0...leWeek.songs.length)
    		{
    			leSongs.push(leWeek.songs[j][0]);
    			leChars.push(leWeek.songs[j][1]);
    		}
    
    		WeekData.setDirectoryFromWeek(leWeek);
    		for (song in leWeek.songs)
    		{
    			var colors:Array<Int> = song[2];
    			if(colors == null || colors.length < 3)
    			{
    				colors = [146, 113, 253];
    			}
    			addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
    		}
    	}
    	Mods.loadTopMod();
    
    	WeekData.setDirectoryFromWeek();
    	
    	for (i in 0...songs.length)
    	{
    		var songText = new FlxText((i <= curSelected) ? baseX - (curSelected-i)*25 : baseX - (i-curSelected)*25, 320+(i-curSelected)*115, 0, songs[i].songName, 60);
    		songText.setFormat(Paths.font("syht.ttf"), 60, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    		if (songs[i].songName.length >= 15) {
    			songText.scale.x = 10 / songs[i].songName.length;
    			songText.updateHitbox();
    		}
    		add(songText);
    		
    		songtextsLastY.push(songText.y);
    		songtextsGroup.push(songText);
    		
    		Mods.currentModDirectory = songs[i].folder;
		
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.scale.set(0.8, 0.8);
			add(icon);
			iconsArray.push(icon);
    	}
    	
    	var bars = new FlxSprite().loadGraphic(Paths.image('menus/freeplaybars'));
    	bars.antialiasing = ClientPrefs.data.antialiasing;
    	bars.screenCenter();
    	
    	bg.color = songs[curSelected].color;
    	changeSelection(0);
    	add(bars);
	
		super.create();
	}

	override function closeSubState() {
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();
	}

	var instPlaying:Int = -1;
	public static var vocals:FlxSound = null;
	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}
		
		
		/* var ratingSplit:Array<String> = Std.string(CoolUtil.floorDecimal(lerpRating * 100, 2)).split('.');
		if(ratingSplit.length < 2) { //No decimals, add an empty space
			ratingSplit.push('');
		}
		
		while(ratingSplit[1].length < 2) { //Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';
		}

		scoreText.text = 'PERSONAL BEST: ' + lerpScore + ' (' + ratingSplit.join('.') + '%)'; */
		
		if (controls.UI_UP_P && !touchMoving)
		{
			changeSelection(-1);
			moveByCurSelected();
		}
		if (controls.UI_DOWN_P && !touchMoving)
		{
			changeSelection(1);
			moveByCurSelected();
		}

		if (FlxG.mouse.overlaps(leftArrow) && FlxG.mouse.justPressed) changeDiff(-1);
		if (FlxG.mouse.overlaps(rightArrow) && FlxG.mouse.justPressed) changeDiff(1);
	
		if (FlxG.mouse.overlaps(leftArrow) && FlxG.mouse.pressed) leftArrow.animation.play('press');
		else leftArrow.animation.play('idle');
		if (FlxG.mouse.overlaps(rightArrow) && FlxG.mouse.pressed) rightArrow.animation.play('press');
		else rightArrow.animation.play('idle');
		
		if (controls.UI_LEFT_P) changeDiff(-1);
		if (controls.UI_RIGHT_P) changeDiff(1);
	
		if (controls.UI_LEFT) leftArrow.animation.play('press');
		else leftArrow.animation.play('idle');
		if (controls.UI_RIGHT) rightArrow.animation.play('press');
		else rightArrow.animation.play('idle');
		
		if (curSelectedels > (songs.length + 2))
			curSelectedels = 0;
		else if (curSelectedels < -3)
			curSelectedels = songs.length - 1;
		
		if (curSelectedels > (songs.length - 1))
    		curSelectedels = songs.length - 1;
    	else if (curSelectedels < 0)
    		curSelectedels = 0;
    
    	if (FlxG.mouse.justPressed && FlxG.mouse.y < 400)
    	{
    		lastMouseY = FlxG.mouse.y;
    		curSelectedels = curSelected;
    		touchMoving = true;
    		
    		if (changingYTween != null && changingXTween != null)
    		{
    			changingYTween.cancel;
    			changingXTween.cancel;
    		}
    	}
    	
    	if (FlxG.mouse.pressed && touchMoving)
    	{	
    		for (i in 0...songs.length)
    		{
    			var songY = songtextsLastY[i];
    			curSelectedels = curSelected - (FlxG.mouse.y - lastMouseY) / 115;
    		
    			songtextsGroup[i].y =  320+(i-curSelectedels)*115;
    			if (i <= curSelectedels)
    				songtextsGroup[i].x = baseX - (curSelectedels-i)*25;
    			else
    				songtextsGroup[i].x = baseX - (i-curSelectedels)*25;
    		}
    	}
    	
    	if (FlxG.mouse.justReleased && touchMoving)
    	{
    		if (Math.round(curSelectedels) != curSelected) {
    			curSelected = Math.round(curSelectedels);
    			changeSelection(0);
    		}
    		
    		touchMoving = false;
    		
    		if (changingYTween != null && changingXTween != null)
    		{
    			changingYTween.cancel;
    			changingXTween.cancel;
    		}
    		
    		if (FlxG.mouse.y > lastMouseY - 10 && FlxG.mouse.y < lastMouseY + 10)
    		{
    			for (i in 0...songs.length) {
    				if (FlxG.mouse.overlaps(songtextsGroup[i]))
    				{
    					curSelected = i;
    					changeSelection();
    					break;
    				}
    			}
    		}
    		
    		moveByCurSelected();
    	}
    	
    	for (i in 0...songs.length) {
			iconsArray[i].x = songtextsGroup[i].x - 150;
			iconsArray[i].y = songtextsGroup[i].y - 25;
		}
		
		if (controls.ACCEPT || FlxG.mouse.justReleased && FlxG.mouse.overlaps(illustration))
    	{
    		FlxG.mouse.visible = false;
    		var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
    		var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
    		try
    		{
    			PlayState.SONG = Song.loadFromJson(poop, songLowercase);
    			PlayState.isStoryMode = false;
    			PlayState.storyDifficulty = curDifficulty;
    
    			if(colorTween != null) {
    				colorTween.cancel();
    			}
    		}
    		catch(e:Dynamic)
    		{
    			var errorStr:String = Mods.currentModDirectory + '/data/' + songLowercase + '/' + poop + '.json';
    			var missingText:FlxText = new FlxText(0, 680, 0, 'ERROR WHILE LOADING CHART: $errorStr', 20);
    			missingText.setFormat(Paths.font("syht.ttf"), 20, FlxColor.WHITE, 'left');
    			add(missingText);
    			
    			missingText.visible = true;
    			
    			new FlxTimer().start(2, function(tmr:FlxTimer) {
    			if(tmr.finished)
    				missingText.visible = false;
    			});
    			FlxG.sound.play(Paths.sound('cancelMenu'));
    
    			return;
    		}
    		
    		LoadingState.loadAndSwitchState(new PlayState());
    
    		FlxG.sound.music.volume = 0;
    				
    		destroyFreeplayVocals();
    		#if desktop
    		DiscordClient.loadModRPC();
    		#end
    	}

		super.update(elapsed);
	}

	public static function destroyFreeplayVocals() {
		if(vocals != null) {
			vocals.stop();
			vocals.destroy();
		}
		vocals = null;
	}
	
    function changeDiff(value:Int)
    {
    	curDifficulty += value;
    	if (curDifficulty < 0)
    		curDifficulty = Difficulty.list.length-1;
    	if (curDifficulty >= Difficulty.list.length)
    		curDifficulty = 0;
    		
    	var newDiffName:String = Difficulty.list[curDifficulty];
    	if ( Paths.image('menudifficulties/' + Paths.formatToSongPath(newDiffName)) != null) {
    		if (difficultieImage != null) {
    			difficultieImage.loadGraphic(Paths.image('menudifficulties/' + Paths.formatToSongPath(newDiffName)));
    			difficultieImage.updateHitbox();
    		} else {
    			difficultieImage = new FlxSprite(0, 625).loadGraphic(Paths.image('menudifficulties/' + Paths.formatToSongPath(newDiffName)));
    			add(difficultieImage);
    		}
    		
    		difficultieImage.x = 1025 - difficultieImage.width/2;
    		rightArrow.x = difficultieImage.x + difficultieImage.width + 15;
    		leftArrow.x = difficultieImage.x - 65;
    		
    		if (difficultieImage != null) difficultieImage.alpha = 1;
    		if (difficultieText != null) difficultieText.alpha = 0;
    	} else {
    		if (difficultieText != null) {
    			difficultieText.text = newDiffName;
    			difficultieText.updateHitbox();
    		} else {
    			difficultieText = new FlxText(0, 625, 0, newDiffName, 60);
    			add(difficultieText);
    		}
    		
    		difficultieText.x = 1025 - difficultieText.width/2;
    		rightArrow.x = difficultieText.x + difficultieText.width + 15;
    		leftArrow.x = difficultieText.x - 65;
    		
    		if (difficultieImage != null) difficultieImage.alpha = 0;
    		if (difficultieText != null) difficultieText.alpha = 1;
    	}
    }

	function changeSelection(value:Int = 0, playSound:Bool = true)
	{
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		
		curSelected += value;
    	if (curSelected > (songs.length - 1))
    		curSelected = 0;
    	else if (curSelected < 0)
    		curSelected = songs.length - 1;
    		 
    	for (i in 0...songs.length) {
    		iconsArray[i].alpha = 0.5;
    		songtextsGroup[i].alpha = 0.5;
    	}
    	
    	iconsArray[curSelected].alpha = 1;
    	songtextsGroup[curSelected].alpha = 1;
    	
    	resetIllustration();
    	
    	var newColor:Int = songs[curSelected].color;
    	if(newColor != intendedColor) {
    		if(colorTween != null) {
    			colorTween.cancel();
    		}
    		intendedColor = newColor;
    		colorTween = FlxTween.color(bg, 0.5, bg.color, intendedColor, {
    			onComplete: function(twn:FlxTween) {
    				colorTween = null;
    			}
    		});
    	}
    	
    	Mods.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;
		Difficulty.loadFromWeek();
	
		changeDiff(0);
	}
	
    function resetIllustration()
    {
    	Mods.currentModDirectory = songs[curSelected].folder;
    	
    	var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
    	if (Paths.image('illustrations/' + songLowercase) != null) {
    		illustration.loadGraphic(Paths.image('illustrations/' + songLowercase));
    		illustration.scale.x = 425/illustration.width;
    		illustration.scale.y = 425/illustration.height;
    		illustration.updateHitbox();
    	} else {
    		illustration.loadGraphic(Paths.image('illustrations/default'));
    		illustration.scale.x = 425/illustration.width;
    		illustration.scale.y = 425/illustration.height;
    		illustration.updateHitbox();
    	}
    	
    	illustration.angle = 0;
    	illustrationBG.angle = 0;
    	illustrationOverlap.angle = 0;
    	
    	if (angleTween != null)
    		angleTween.cancel;
    	
    	angleTween = FlxTween.tween(illustration, {angle: -5}, 0.25, {ease: FlxEase.quadOut});
    	angleTweenBG = FlxTween.tween(illustrationBG, {angle: -5}, 0.25, {ease: FlxEase.quadOut});
    	angleTweenOverlap = FlxTween.tween(illustrationOverlap, {angle: -5}, 0.25, {ease: FlxEase.quadOut});
    	
    	illustrationOverlap.alpha = 0.75;
    	FlxTween.tween(illustrationOverlap, {alpha: 0}, 0.25, {ease: FlxEase.quadOut});
    }
    
    
	
	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}
	
	function moveByCurSelected()
	{
		for (songnum in 0...songs.length) {
			changingXTween = FlxTween.tween(songtextsGroup[songnum], {x: (songnum <= curSelected) ? baseX - (curSelected-songnum)*25 : baseX - (songnum-curSelected)*25}, 0.4, {ease: FlxEase.quadOut});
			changingYTween = FlxTween.tween(songtextsGroup[songnum], {y: 320+(songnum-curSelected)*115}, 0.4, {ease: FlxEase.quadOut});
		}
	}
}