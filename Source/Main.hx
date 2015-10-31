package;


import haxe.io.Path;
import haxe.macro.Compiler;
import lime.system.BackgroundWorker;
import lime.tools.helpers.PathHelper;
import lime.tools.helpers.PlatformHelper;
import lime.tools.helpers.ProcessHelper;
import motion.Actuate;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.Assets;
import sys.FileSystem;
import sys.io.File;
import task.Task;
import task.TaskManager;


class Main extends Display {
	
	
	private static var TASK_INSTALL_HAXE = "installHaxe";
	private static var TASK_INSTALL_LIME = "installLime";
	private static var TASK_INSTALL_OPENFL = "installOpenFL";
	private static var TASK_SETUP_OPENFL = "setupOpenFL";
	
	
	public function new () {
		
		super ();
		
		Logo.alpha = 0;
		StatusText.alpha = 0;
		InstallButton.alpha = 0;
		
		Actuate.tween (Logo, 2, { alpha: 1 } ).delay (0.2);
		Actuate.tween (InstallButton, 1, { alpha: 1 } ).delay (0.8);
		
		UpgradeButton.visible = false;
		
		InstallButton.buttonMode = true;
		InstallButton.mouseChildren = false;
		InstallButton.addEventListener (MouseEvent.MOUSE_DOWN, InstallButton_onMouseDown);
		
		StatusText.text = "";
		
		//var tempFile = PathHelper.getTemporaryFile ();
		//var output = ProcessHelper.runProcess ("", "cmd", [ "/C", "haxelib", "version" ], true, true, true);
		//Sys.println (StringTools.trim (output));
		//if (FileSystem.exists (tempFile)) {
			//
			//Sys.println (tempFile);
			//
		//}
		
	}
	
	
	private function installHaxe ():Void {
		
		StatusText.text = "Running Haxe Installer...";
		
		Actuate.timer (1.2).onComplete (function () {
			
			var path = PathHelper.getTemporaryDirectory ();
			PathHelper.mkdir (path);
			path = PathHelper.combine (path, "haxe-installer.exe");
			File.saveBytes (path, Assets.getBytes ("haxe"));
			
			switch (PlatformHelper.hostPlatform) {
				
				case WINDOWS: ProcessHelper.runProcess ("", "cmd", [ "/c", path ], true, true, true);
				case MAC: ProcessHelper.runProcess ("", "open", [ path ], true, true, true);
				default: ProcessHelper.runProcess ("", "xdg-open", [ path ], true, true, true);
				
			}
			
			PathHelper.removeDirectory (Path.directory (path));
			TaskManager.completeTask (TASK_INSTALL_HAXE);
			
		});
		
	}
	
	
	private function installLime ():Void {
		
		StatusText.text = "Installing Lime...";
		
		var path = PathHelper.getTemporaryFile (".zip");
		var output = File.write (path);
		
		var limeSegmentCount = Std.parseInt (Compiler.getDefine ("LIME_SEGMENT_COUNT"));
		
		for (i in 0...limeSegmentCount) {
			
			output.write (Assets.getBytes ("lime_segment" + i));
			
		}
		
		output.close ();
		
		var worker = new BackgroundWorker ();
		worker.doWork.add (function (_) {
			
			ProcessHelper.runProcess ("", "haxelib", [ "local", path ], true, true, true);
			worker.sendComplete ();
			
		});
			
		worker.onComplete.add (function (_) {
			try {
				
				FileSystem.deleteFile (path);
				
			} catch (e:Dynamic) { }
			
			TaskManager.completeTask (TASK_INSTALL_LIME);
			
		});
		worker.run ();
		
	}
	
	
	private function installOpenFL ():Void {
		
		StatusText.text = "Installing OpenFL...";
		
		var path = PathHelper.getTemporaryFile (".zip");
		File.saveBytes (path, Assets.getBytes ("openfl"));
		
		var worker = new BackgroundWorker ();
		worker.doWork.add (function (_) {
			
			ProcessHelper.runProcess ("", "haxelib", [ "local", path ], true, true, true);
			worker.sendComplete ();
			
		});
		worker.onComplete.add (function (_) {
			
			try {
				
				FileSystem.deleteFile (path);
				
			} catch (e:Dynamic) { }
			
			TaskManager.completeTask (TASK_INSTALL_OPENFL);
			
		});
		worker.run ();
		
	}
	
	
	private function setupOpenFL ():Void {
		
		StatusText.text = "Setting Up OpenFL...";
		
		var worker = new BackgroundWorker ();
		worker.doWork.add (function (_) {
			
			ProcessHelper.runProcess ("", "haxelib", [ "run", "openfl", "setup", "-y" ], true, true, true);
			worker.sendComplete ();
			
		});
		worker.onComplete.add (function (_) {
			
			StatusText.text = "Done!";
			
			TaskManager.completeTask (TASK_SETUP_OPENFL);
			
		});
		worker.run ();
		
	}
	
	
	
	
	// Event Handlers
	
	
	
	
	private function InstallButton_onMouseDown (event:MouseEvent):Void {
		
		InstallButton.mouseEnabled = false;
		Actuate.tween (InstallButton, 2, { alpha: 0 } );
		Actuate.tween (StatusText, 2, { alpha: 1 } );
		
		TaskManager.addTask (new Task (TASK_INSTALL_HAXE, installHaxe), null, false);
		TaskManager.addTask (new Task (TASK_INSTALL_LIME, installLime), [ TASK_INSTALL_HAXE ], false);
		TaskManager.addTask (new Task (TASK_INSTALL_OPENFL, installOpenFL), [ TASK_INSTALL_LIME ], false);
		TaskManager.addTask (new Task (TASK_SETUP_OPENFL, setupOpenFL), [ TASK_INSTALL_OPENFL ], false);
		
	}
	
	
}