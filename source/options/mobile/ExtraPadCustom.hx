package options.mobile;

import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import android.flixel.FlxButton;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import android.FlxVirtualPad;

using StringTools;

class AndroidControlsMenu extends MusicBeatState
{
	var vpad:FlxVirtualPad;
	//var hbox:FlxHitbox;
	var newhbox:FlxNewHitbox;
	var spacePozition:FlxText;
	var shiftPozition:FlxText;
	var inputvari:PsychAlphabet;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;
	var bindButton:FlxButton;
	var resetButton:FlxButton;
	var buttonistouched:Bool = false;
	var bindbutton:FlxButton;

	override public function create():Void
	{
		super.create();
		
		var bg:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFea71fd;
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		var titleText:Alphabet = new Alphabet(75, 60, "Mobile Extra Controls", true);
		titleText.scaleX = 0.6;
		titleText.scaleY = 0.6;
		titleText.alpha = 0.4;
		add(titleText);

		vpad = new FlxVirtualPad(EXTRA, NONE, 0.75, ClientPrefs.data.antialiasing);
		vpad.alpha = 0;
		add(vpad);
		loadcustom()

		inputvari = new PsychAlphabet(0, 50, 'Custom Extra Button', false, false, 0.05, 0.8);
		inputvari.screenCenter(X);
		add(inputvari);

		spacePozition = new FlxText(10, FlxG.height - 104, 0,"Button Up X:" + vpad.buttonUp.x +" Y:" + vpad.buttonUp.y, 16);
		spacePozition.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		spacePozition.borderSize = 2.4;
		add(spacePozition);

		shiftPozition = new FlxText(10, FlxG.height - 84, 0,"Button Down X:" + vpad.buttonDown.x +" Y:" + vpad.buttonDown.y, 16);
		shiftPozition.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		shiftPozition.borderSize = 2.4;
		add(shiftPozition);
		
		var exitButton:FlxButton = new FlxButton(FlxG.width - 200, 50, 'Exit', function()
		{
			save();
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new options.mobile.MobileOptionsState());
		}

		});
		exitButton.setGraphicSize(Std.int(exitButton.width) * 3);
		exitButton.label.setFormat(Paths.font('vcr.ttf'), 21, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, true);
		exitButton.color = FlxColor.LIME;
		add(exitButton);

		resetButton = new FlxButton(exitButton.x, exitButton.y + 100, 'Reset', function()
		{
			if (resetButton.visible)
			{
				if (controlitems[Math.floor(curSelected)] == 'Pad-Custom')
				{
					vpad.buttonSpace.x = FlxG.width - 86 * 3;
					vpad.buttonShift.x = FlxG.width - 128 * 3;
					
					vpad.buttonSpace.y = FlxG.height - 66 - 116 * 3;
					vpad.buttonShift.y = FlxG.height - 66 - 81 * 3;
				}
			}
		}
		resetButton.setGraphicSize(Std.int(resetButton.width) * 3);
		resetButton.label.setFormat(Paths.font('vcr.ttf'), 21, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, true);
		resetButton.color = FlxColor.RED;
		resetButton.visible = false;
		add(resetButton);

		changeSelection();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	function trackbutton(touch:flixel.input.touch.FlxTouch)
	{
		if (buttonistouched){
			if (bindbutton.justReleased && touch.justReleased)
			{
				bindbutton = null;
				buttonistouched = false;
			}else 
			{
				movebutton(touch, bindbutton);
				setbuttontexts();
			}
		}
		else 
		{
			if (vpad.buttonSpace.justPressed) {
				movebutton(touch, vpad.buttonSpace);
			}
			
			if (vpad.buttonShift.justPressed) {
				movebutton(touch, vpad.buttonShift);
			}
		}
	}

	function movebutton(touch:flixel.input.touch.FlxTouch, button:android.flixel.FlxButton) {
		button.x = touch.x - vpad.buttonUp.width / 2;
		button.y = touch.y - vpad.buttonUp.height / 2;
		bindbutton = button;
		buttonistouched = true;
	}

	function setbuttontexts() {
		spacePozition.text = "Button Space X:" + vpad.buttonSpace.x +" Y:" + vpad.buttonSpace.y;
		shiftPozition.text = "Button Shift X:" + vpad.buttonShift.x +" Y:" + vpad.buttonShift.y;
	}

	function save() {
		Config.savecustom(vpad);
	}

	function loadcustom():Void{
		vpad = Config.loadcustom(vpad);	
	}
}

class Config {
	var save:FlxSave;

	public function new() {
		save = new FlxSave();
		save.bind("saved-controlsExtra");
	}

	public function savecustom(_pad:FlxVirtualPad) {
		if (save.data.buttons == null)
		{
			save.data.buttons = new Array();
			for (buttons in _pad){
				save.data.buttons.push(FlxPoint.get(buttons.x, buttons.y));
			}
		}else{
			var tempCount:Int = 0;
			for (buttons in _pad){
				save.data.buttons[tempCount] = FlxPoint.get(buttons.x, buttons.y);
				tempCount++;
			}
		}
		save.flush();
	}

	public function loadcustom(_pad:FlxVirtualPad):FlxVirtualPad {
		if (save.data.buttons == null) 
			return _pad;
		var tempCount:Int = 0;
		for(buttons in _pad){
			buttons.x = save.data.buttons[tempCount].x;
			buttons.y = save.data.buttons[tempCount].y;
			tempCount++;
		}	
		return _pad;
	}
}