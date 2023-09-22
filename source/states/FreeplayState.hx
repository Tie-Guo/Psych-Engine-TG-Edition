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
    
    var baseX:Float = 200;
    var lastMouseY:Float = 0;
    var songtextsLastY:Array<Float> = [];
    var touchMoving:Bool = false;
    var curSelected:Int = 5;
    var curSelectedels:Float = 0;
    var intendedColor:Int;
    var iconsArray:Array<HealthIcon> = [];
    
    var changingYTween:FlxTween;
    var changingXTween:FlxTween;
    var colorTween:FlxTween;
    
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
			icon.camera = game.camOther;
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

		#if android
			addVirtualPad(FULL, A_B_C_X_Y_Z);
		#end
				
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
		
		if (curSelectedels > (songs.length - 1))
    		curSelectedels = songs.length - 1;
    	else if (curSelectedels < 0)
    		curSelectedels = 0;
    
    	if (FlxG.mouse.justPressed)
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
    	
    	if (FlxG.mouse.pressed)
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
    	
    	if (FlxG.mouse.justReleased)
    	{
    		for (i in 0...songs.length)
    			songtextsLastY[i] = songtextsGroup[i].y;
    		
    		curSelected = Math.round(curSelectedels);
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
						break;
					}
				}
			}
    		
    		changeSelection(0);
    	}
    	
    	for (i in 0...songs.length) {
			iconsArray[i].x = songtextsGroup[i].x - 150;
			iconsArray[i].y = songtextsGroup[i].y - 25;
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

	function changeDiff(change:Int = 0)
	{
	
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
    		moveByCurSelected(i, curSelected);
    		
    		iconsArray[i].alpha = 0.5;
    		songtextsGroup[i].alpha = 0.5;
    	}
    	
    	iconsArray[curSelected].alpha = 1;
    	songtextsGroup[curSelected].alpha = 1;
    	
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
	}
	
	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}
	
	function moveByCurSelected(songnum, curSelected)
	{
		changingXTween = FlxTween.tween(songtextsGroup[songnum], {x: (songnum <= curSelected) ? baseX - (curSelected-songnum)*25 : baseX - (songnum-curSelected)*25}, 0.4, {ease: FlxEase.quadOut});
		changingYTween = FlxTween.tween(songtextsGroup[songnum], {y: 320+(songnum-curSelected)*115}, 0.4, {ease: FlxEase.quadOut});
	}
}