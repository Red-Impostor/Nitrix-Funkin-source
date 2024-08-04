package grafex.states;

import grafex.states.options.substates.Options.Option;
import grafex.system.log.GrfxLogger;
import grafex.states.options.OptionsDirect;
import grafex.system.Paths;
import grafex.system.statesystem.MusicBeatState;
#if desktop
import external.Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.system.FlxAssets;
import flixel.util.FlxColor;
import grafex.data.WeekData;
import flixel.system.FlxAssets.FlxShader;
import lime.app.Application;
import grafex.states.editors.MasterEditorMenu;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxTimer;
import flixel.addons.display.FlxBackdrop;
import grafex.data.EngineData;
import grafex.system.Conductor;
import grafex.util.ClientPrefs;
import grafex.util.Utils;
import flixel.ui.FlxButton;
using StringTools;

class MainMenuState extends MusicBeatState
{
	public static var curSelected:Int = 0;

	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;
	
	var menuItems:FlxTypedGroup<FlxSprite>;
	public var movingBG:FlxBackdrop;
	
	var playbut = new FlxButton();
	var credbut = new FlxButton();
	var optbut = new FlxButton();
	var screambut = new FlxButton();
	var screamer = new FlxSprite();

    public static var firstStart:Bool = true;

	var boxMain:FlxSprite;
	var optionShit:Array<String> = ['freeplay', 'credits', 'options'];

	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var debugKeys:Array<FlxKey>;

	var arrowLeftKeys:Array<FlxKey>;
	var arrowRightKeys:Array<FlxKey>;

    public static var finishedFunnyMove:Bool = false;
        
    override function create()
	{
		Paths.clearStoredMemory();
		
		GrfxLogger.log('info', 'Switched state to: ' + Type.getClassName(Type.getClass(this)));
		
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menu", null);
		#end
        WeekData.loadTheFirstEnabledMod();
        FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

        if(FlxG.sound.music != null)
			if (!FlxG.sound.music.playing)
			{	
				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.7);
        		FlxG.sound.music.time = 9400;
				TitleState.titleJSON = TitleState.getTitleData();
				Conductor.changeBPM(TitleState.titleJSON.bpm);
			}

		Application.current.window.title = Main.appTitle + ' - Main Menu';
		
		camGame = new FlxCamera();

		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));	
		arrowRightKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('ui_right'));
		arrowLeftKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('ui_left'));
		
		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement);
		FlxCamera.defaultCameras = [camGame];
		//FlxG.cameras.setDefaultDrawTarget(camGame, true);
		
		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
		
		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		movingBG = new FlxBackdrop(Paths.image('menuDesat'), 10, 0, true, true);
		movingBG.scrollFactor.set(0,0);
		movingBG.color = 0xfffde871;
        movingBG.velocity.x = -90;
		add(movingBG);
		
		final grid = new flixel.addons.display.FlxBackdrop(flixel.addons.display.FlxGridOverlay.createGrid(1, 1, 2, 2, true, 0x33FFFFFF, 0x0));
		grid.scrollFactor.set(0, yScroll);
		grid.velocity.set(40, 40);
		grid.scale.scale(80);
		add(grid);
		
		playbut.loadGraphic(Paths.image('mainmenu/play'));
		playbut.scale.set(0.3,0.3);
		playbut.updateHitbox();
		playbut.x = 100;
		playbut.screenCenter(Y);
		add(playbut);

		credbut.loadGraphic(Paths.image('mainmenu/credits'));
		credbut.scale.set(0.3,0.3);
		credbut.updateHitbox();
		credbut.x = 500;
		credbut.screenCenter(Y);
		add(credbut);
       
		optbut.loadGraphic(Paths.image('mainmenu/option'));
		optbut.scale.set(0.3,0.3);
		optbut.updateHitbox();
		optbut.x = 900;
		optbut.screenCenter(Y);
		add(optbut);

		screambut.loadGraphic(Paths.image('mainmenu/screambutton'));
		screambut.scale.set(0.1,0.1);
		screambut.updateHitbox();
		screambut.x = 1215;
		screambut.y = 650;
		add(screambut);

		screamer.loadGraphic(Paths.image('mainmenu/scream'));
		screamer.visible = false;
		
		screamer.alpha = 1;
		screamer.updateHitbox();
		
		screamer.screenCenter();
		screamer.scale.set(2,2);
		add(screamer);

		var scale:Float = 1;

		FlxG.camera.follow(camFollowPos, null, 1);

		var versionShit:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v0.2.8", 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		changeItem();

		super.create();
	}

	var selectedSomethin:Bool = false;
	var clickCount:Int = 0;
	var colorEntry:FlxColor;
	
	override function update(elapsed:Float)
	{		
		if (FlxG.sound.music != null)
            Conductor.songPosition = FlxG.sound.music.time;

		//Conductor.songPosition = FlxG.sound.music.time; // this is such a bullshit, we messed with this around 2 hours - Xale
		playbut.onOver.callback = playOver;
		playbut.onOut.callback = notplayOver;

		credbut.onOver.callback = credOver;
		credbut.onOut.callback = notcredOver;

		optbut.onOver.callback = optOver;
		optbut.onOut.callback = notoptOver;

		screambut.onOver.callback = screamOver;
		screambut.onOut.callback = notscreamOver;


		if (FlxG.mouse.overlaps(playbut) && FlxG.mouse.justPressed ){
			FlxG.sound.play(Paths.sound('confirmMenu'));
			MusicBeatState.switchState(new FreeplayState());
		}

		if (FlxG.mouse.overlaps(credbut) && FlxG.mouse.justPressed ){
			FlxG.sound.play(Paths.sound('confirmMenu'));
			MusicBeatState.switchState(new CreditsState());
		}

		if (FlxG.mouse.overlaps(optbut) && FlxG.mouse.justPressed ){
			FlxG.sound.play(Paths.sound('confirmMenu'));
			FlxTransitionableState.skipNextTransIn = false;
            FlxTransitionableState.skipNextTransOut = false;
			MusicBeatState.switchState(new OptionsDirect());
		}

		if (FlxG.mouse.overlaps(screambut) && FlxG.mouse.justPressed ){
			FlxG.sound.play(Paths.sound('scream'));
		}

		var lerpVal:Float = Utils.boundTo(elapsed * 9, 0, 1);
        
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		if (!selectedSomethin)
		{
            if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
                TitleState.fromMainMenu = true;
			}
			
			#if desktop
			else if (FlxG.keys.anyJustPressed(debugKeys))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		FlxG.watch.addQuick("beatShit", curBeat);

		super.update(elapsed);

        var elapsedTime:Float = elapsed*6;
	}

    function changeItem(huh:Int = 0)
	{
		if (finishedFunnyMove)
		{
			curSelected += huh;
		}
	}
	function playOver(){
		FlxTween.tween(playbut, {'scale.x':0.32,'scale.y':0.32}, 0.3, {ease: FlxEase.quadOut});
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
	function notplayOver(){
		FlxTween.tween(playbut, {'scale.x':0.30,'scale.y':0.30}, 0.3, {ease: FlxEase.quadOut});
	}

	function credOver(){
		FlxTween.tween(credbut, {'scale.x':0.32,'scale.y':0.32}, 0.3, {ease: FlxEase.quadOut});
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
	function notcredOver(){
		FlxTween.tween(credbut, {'scale.x':0.30,'scale.y':0.30}, 0.3, {ease: FlxEase.quadOut});
	}

	function optOver(){
		FlxTween.tween(optbut, {'scale.x':0.32,'scale.y':0.32}, 0.3, {ease: FlxEase.quadOut});
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
	function notoptOver(){
		FlxTween.tween(optbut, {'scale.x':0.30,'scale.y':0.30}, 0.3, {ease: FlxEase.quadOut});
	}

	function screamOver(){
		FlxTween.tween(screambut, {'scale.x':0.12,'scale.y':0.12}, 0.3, {ease: FlxEase.quadOut});
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
	function notscreamOver(){
		FlxTween.tween(screambut, {'scale.x':0.10,'scale.y':0.10}, 0.3, {ease: FlxEase.quadOut});
	}
}
