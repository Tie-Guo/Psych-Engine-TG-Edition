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
import states.FreeplayState;
import flixel.ui.FlxButton;

#if MODS_ALLOWED
import sys.FileSystem;
#end

class FreeplaySearchState extends MusicBeatState
{
	public static var songs:Array<SongMetadata> = [];

	var selector:FlxText;
	private static var curSelected:Int = 0;
	var lerpSelected:Float = 0;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = Difficulty.getDefault();

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;

	var missingTextBG:FlxSprite;
	var missingText:FlxText;
	
	var showSearch:Bool = true;
	var showCaseBGTween:FlxTween;
	var reduceDataBG:FlxSprite;
	var reduceDataBGText:FlxText;
	var searchTextBG:FlxSprite;
	var searchInput:FlxInputText;
	var searchText:FlxText;
	var underline:FlxSprite;
	var searchButton:FlxButton;

	override function create()
	{
		//Paths.clearStoredMemory();
		//Paths.clearUnusedMemory();
		
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);
		
		FlxG.mouse.visible = true;

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		Mods.loadTopMod();

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(90, 320, songs[i].songName, true);
			songText.targetY = i;
			grpSongs.add(songText);

			songText.scaleX = Math.min(1, 980 / songText.width);
			songText.snapToPosition();

			Mods.currentModDirectory = songs[i].folder;
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			
			// too laggy with a lot of songs, so i had to recode the logic for it
			songText.visible = songText.active = songText.isMenuItem = false;
			icon.visible = icon.active = false;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}
		WeekData.setDirectoryFromWeek();

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);
		
		searchTextBG = new FlxSprite(FlxG.width-450, 200).makeGraphic(450, 166, FlxColor.BLACK);
		searchTextBG.alpha = 0.6;
		
		searchInput = new FlxInputText(FlxG.width-425, 220, 400, '', 30, 0x00FFFFFF);
		searchInput.focusGained = () -> FlxG.stage.window.textInputEnabled = true;
		searchInput.backgroundColor = FlxColor.TRANSPARENT;
		searchInput.fieldBorderColor = FlxColor.TRANSPARENT;
		searchInput.font = Language.font();
		
		underline = new FlxSprite(FlxG.width-425, 260).makeGraphic(400, 6, FlxColor.WHITE);
		underline.alpha = 0.6;
		
		searchButton = new FlxButton(FlxG.width-150, 313, "Search Songs", function() {
			doSearch();
		});
		searchButton.scale.set(2.75, 2.75);
		searchButton.alpha = 0;
		
		searchText = new FlxText(FlxG.width-220, 310, 300, 'Search Songs' + #if android '(Touch)' #else '(S)' #end, 24);
		searchText.setFormat(Language.font(), 24, FlxColor.WHITE, RIGHT);
		
		reduceDataBG = new FlxSprite(FlxG.width - 75, 366).makeGraphic(75 , 75, 0xFFFFFFFF);
		reduceDataBG.color = 0xFF000000;
		add(reduceDataBG);
		
		reduceDataBGText = new FlxText(FlxG.width - 50, 340, 0, '>', 40);
    	reduceDataBGText.setFormat(Language.font(), 40, FlxColor.WHITE);
    	add(reduceDataBGText);
		
		var ypos:Int = -30;
		searchTextBG.y += ypos;
		searchInput.y += ypos;
		underline.y += ypos;
		searchText.y += ypos;
		searchButton.y += ypos;
		reduceDataBG.y += ypos;
		
		var xpos:Int = 20;
		searchTextBG.x += xpos;
		searchInput.x += xpos;
		underline.x += xpos;
		
		add(searchTextBG);
		add(searchInput);
		add(underline);
		add(searchText);
		add(searchButton);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		add(scoreText);

		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);
		
		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

		if(curSelected >= songs.length) curSelected = 0;
		bg.color = songs[curSelected].color;
		intendedColor = bg.color;
		lerpSelected = curSelected;

		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));
		
		changeSelection();

		var swag:Alphabet = new Alphabet(1, 0, "swag");

		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);

		#if PRELOAD_ALL
		#if android
		var leText:String = "Press X to listen to the Song / Press C to open the Gameplay Changers Menu / Press Y to Reset your Score and Accuracy.";
		var size:Int = 16;
		#else
		var leText:String = "Press SPACE to listen to the Song / Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
		var size:Int = 16;
		#end
		#else
		var leText:String = "Press C to open the Gameplay Changers Menu / Press Y to Reset your Score and Accuracy.";
		var size:Int = 18;
		#end
		var text:FlxText = new FlxText(textBG.x, textBG.y + 4, FlxG.width, leText, size);
		text.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, RIGHT);
		text.scrollFactor.set();
		add(text);
		
		updateTexts();
		
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
	
	function doSearch()
	{
		var suitedSong:Array<SongMetadata> = [];
		var searchString = searchInput.text.toLowerCase();
		var fsongs:Array<SongMetadata> = FreeplayState.songs;
		for (i in 0...fsongs.length)
		{
			var name:String = fsongs[i].songName.toLowerCase();
			if (name.indexOf(searchString) != -1)
			{
				suitedSong.push(fsongs[i]);
			}
		}
		
		if (suitedSong.length < 1) {
			FlxG.sound.play(Paths.sound('cancelMenu'));
			return;
		}
		
		songs = suitedSong;
		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;
		MusicBeatState.resetState();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	/*public function addWeek(songs:Array<String>, weekNum:Int, weekColor:Int, ?songCharacters:Array<String>)
	{
		if (songCharacters == null)
			songCharacters = ['bf'];

		var num:Int = 0;
		for (song in songs)
		{
			addSong(song, weekNum, songCharacters[num]);
			this.songs[this.songs.length-1].color = weekColor;

			if (songCharacters.length != 1)
				num++;
		}
	}*/

	var instPlaying:Int = -1;
	public static var vocals:FlxSound = null;
	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		if (FlxG.keys.justPressed.S) doSearch();
		
		if (FlxG.mouse.justPressed)
    	{
    		if (FlxG.mouse.overlaps(reduceDataBG))
    		{
    			reduceDataBG.color = 0xFFFFFFFF;
    			if (showCaseBGTween != null) showCaseBGTween.cancel();
    			showCaseBGTween = FlxTween.color(reduceDataBG, 0.5, 0xFFFFFFFF, 0xFF000000, {ease: FlxEase.sineInOut});
    			showSearch = !showSearch;
    			FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
    		}
    	}
    	
    	searchTextBG.x = FlxMath.lerp(showSearch ? FlxG.width-430 : FlxG.width+100, searchTextBG.x, FlxMath.bound(1 - (elapsed * 9.5), 0, 1));
    	searchInput.x = FlxMath.lerp(showSearch ? FlxG.width-405 : FlxG.width+100, searchInput.x, FlxMath.bound(1 - (elapsed * 9.5), 0, 1));
    	underline.x = FlxMath.lerp(showSearch ? FlxG.width-405 : FlxG.width+100, underline.x, FlxMath.bound(1 - (elapsed * 9.5), 0, 1));
    	searchButton.x = FlxMath.lerp(showSearch ? FlxG.width-130 : FlxG.width+100, searchButton.x, FlxMath.bound(1 - (elapsed * 9.5), 0, 1));
    	searchText.x = FlxMath.lerp(showSearch ? FlxG.width-300 : FlxG.width+100, searchText.x, FlxMath.bound(1 - (elapsed * 9.5), 0, 1));
		
		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, FlxMath.bound(elapsed * 24, 0, 1)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, FlxMath.bound(elapsed * 12, 0, 1));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		var ratingSplit:Array<String> = Std.string(CoolUtil.floorDecimal(lerpRating * 100, 2)).split('.');
		if(ratingSplit.length < 2) { //No decimals, add an empty space
			ratingSplit.push('');
		}
		
		while(ratingSplit[1].length < 2) { //Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';
		}

		scoreText.text = 'PERSONAL BEST: ' + lerpScore + ' (' + ratingSplit.join('.') + '%)';
		positionHighscore();

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT  #if android || MusicBeatState._virtualpad.buttonZ.pressed #end) shiftMult = 3;

		if(songs.length > 1)
		{
			if(FlxG.keys.justPressed.HOME)
			{
				curSelected = 0;
				changeSelection();
				holdTime = 0;
			}
			else if(FlxG.keys.justPressed.END)
			{
				curSelected = songs.length - 1;
				changeSelection();
				holdTime = 0;
			}
			if (controls.UI_UP_P)
			{
				changeSelection(-shiftMult);
				holdTime = 0;
			}
			if (controls.UI_DOWN_P)
			{
				changeSelection(shiftMult);
				holdTime = 0;
			}

			if(controls.UI_DOWN || controls.UI_UP)
			{
				var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
				holdTime += elapsed;
				var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

				if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
			}

			if(FlxG.mouse.wheel != 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
				changeSelection(-shiftMult * FlxG.mouse.wheel, false);
			}
		}

		if (controls.UI_LEFT_P)
		{
			changeDiff(-1);
			_updateSongLastDifficulty();
		}
		else if (controls.UI_RIGHT_P)
		{
			changeDiff(1);
			_updateSongLastDifficulty();
		}

		if (controls.BACK)
		{
			persistentUpdate = false;
			if(colorTween != null) {
				colorTween.cancel();
			}
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new FreeplayState());
		}

		if(FlxG.keys.justPressed.CONTROL #if android || MusicBeatState._virtualpad.buttonC.justPressed #end)
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
		}
		else if(FlxG.keys.justPressed.SPACE #if android || MusicBeatState._virtualpad.buttonX.justPressed #end)
		{
			if(instPlaying != curSelected)
			{
				#if PRELOAD_ALL
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;
				Mods.currentModDirectory = songs[curSelected].folder;
				var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
				PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
				if (PlayState.SONG.needsVoices)
					vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
				else
					vocals = new FlxSound();

				FlxG.sound.list.add(vocals);
				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.7);
				vocals.play();
				vocals.persist = true;
				vocals.looped = true;
				vocals.volume = 0.7;
				instPlaying = curSelected;
				#end
			}
		}

		else if (controls.ACCEPT)
		{
			persistentUpdate = false;
			FlxG.mouse.visible = false;
			var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
			var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
			/*#if MODS_ALLOWED
			if(!sys.FileSystem.exists(Paths.modsJson(songLowercase + '/' + poop)) && !sys.FileSystem.exists(Paths.json(songLowercase + '/' + poop))) {
			#else
			if(!OpenFlAssets.exists(Paths.json(songLowercase + '/' + poop))) {
			#end
				poop = songLowercase;
				curDifficulty = 1;
				trace('Couldnt find file');
			}*/
			trace(poop);

			try
			{
				PlayState.SONG = Song.loadFromJson(poop, songLowercase);
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = curDifficulty;

				trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
				if(colorTween != null) {
					colorTween.cancel();
				}
			}
			catch(e:Dynamic)
			{
				trace('ERROR! $e');
                var errorStr:String = Mods.currentModDirectory + '/data/' + songLowercase + '/' + poop + '.json';
				//var errorStr:String = e.toString();
				/*if(errorStr.startsWith('[file_contents,assets/data/')) errorStr = 'Missing file: ' + errorStr.substring(27, errorStr.length-1); //Missing chart*/
				missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
				missingText.screenCenter(Y);
				missingText.visible = true;
				missingTextBG.visible = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));

				updateTexts(elapsed);
				super.update(elapsed);
				return;
			}
			
			if (FlxG.keys.pressed.SHIFT #if android || MusicBeatState._virtualpad.buttonZ.pressed #end){
				LoadingState.loadAndSwitchState(new ChartingState());
			}else{
				LoadingState.loadAndSwitchState(new PlayState());
			}
			//LoadingState.loadAndSwitchState(new PlayState());

			FlxG.sound.music.volume = 0;
					
			destroyFreeplayVocals();
			#if desktop
			DiscordClient.loadModRPC();
			#end
		}
		else if(controls.RESET #if android || MusicBeatState._virtualpad.buttonY.justPressed #end)
		{
		    #if android
			removeVirtualPad();
			#end
			persistentUpdate = false;
			openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		updateTexts(elapsed);
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
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = Difficulty.list.length-1;
		if (curDifficulty >= Difficulty.list.length)
			curDifficulty = 0;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		lastDifficultyName = Difficulty.getString(curDifficulty);
		if (Difficulty.list.length > 1)
			diffText.text = '< ' + lastDifficultyName.toUpperCase() + ' >';
		else
			diffText.text = lastDifficultyName.toUpperCase();

		positionHighscore();
		missingText.visible = false;
		missingTextBG.visible = false;
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		_updateSongLastDifficulty();
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var lastList:Array<String> = Difficulty.list;
		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;
			
		var newColor:Int = songs[curSelected].color;
		if(newColor != intendedColor) {
			if(colorTween != null) {
				colorTween.cancel();
			}
			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					colorTween = null;
				}
			});
		}

		// selector.y = (70 * curSelected) + 30;

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
		{
			iconArray[i].alpha = 0.6;
		}

		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			bullShit++;
			item.alpha = 0.6;
			if (item.targetY == curSelected)
				item.alpha = 1;
		}
		
		Mods.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;
		Difficulty.loadFromWeek();
		
		var savedDiff:String = songs[curSelected].lastDifficulty;
		var lastDiff:Int = Difficulty.list.indexOf(lastDifficultyName);
		if(savedDiff != null && !lastList.contains(savedDiff) && Difficulty.list.contains(savedDiff))
			curDifficulty = Math.round(Math.max(0, Difficulty.list.indexOf(savedDiff)));
		else if(lastDiff > -1)
			curDifficulty = lastDiff;
		else if(Difficulty.list.contains(Difficulty.getDefault()))
			curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
		else
			curDifficulty = 0;

		changeDiff();
		_updateSongLastDifficulty();
	}

	inline private function _updateSongLastDifficulty()
	{
		songs[curSelected].lastDifficulty = Difficulty.getString(curDifficulty);
	}

	private function positionHighscore() {
		scoreText.x = FlxG.width - scoreText.width - 6;
		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
	}

	var _drawDistance:Int = 4;
	var _lastVisibles:Array<Int> = [];
	public function updateTexts(elapsed:Float = 0.0)
	{
		lerpSelected = FlxMath.lerp(lerpSelected, curSelected, FlxMath.bound(elapsed * 9.6, 0, 1));
		for (i in _lastVisibles)
		{
			grpSongs.members[i].visible = grpSongs.members[i].active = false;
			iconArray[i].visible = iconArray[i].active = false;
		}
		_lastVisibles = [];

		var min:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected - _drawDistance)));
		var max:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected + _drawDistance)));
		for (i in min...max)
		{
			var item:Alphabet = grpSongs.members[i];
			item.visible = item.active = true;
			item.x = ((item.targetY - lerpSelected) * item.distancePerItem.x) + item.startPosition.x;
			item.y = ((item.targetY - lerpSelected) * 1.3 * item.distancePerItem.y) + item.startPosition.y;

			var icon:HealthIcon = iconArray[i];
			icon.visible = icon.active = true;
			_lastVisibles.push(i);
		}
	}
}