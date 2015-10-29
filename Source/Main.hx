package;


import haxe.io.Path;
import lime.tools.helpers.PathHelper;
import lime.tools.helpers.PlatformHelper;
import lime.tools.helpers.ProcessHelper;
import motion.Actuate;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.MouseEvent;
import openfl.events.ProgressEvent;
import openfl.net.URLLoader;
import openfl.net.URLLoaderDataFormat;
import openfl.net.URLRequest;
import sys.FileSystem;
import sys.io.File;
import task.Task;
import task.TaskManager;


class Main extends Display {
	
	
	private static var TASK_INSTALL_HAXE = "installHaxe";
	private static var TASK_INSTALL_LIME = "installLime";
	private static var TASK_INSTALL_OPENFL = "installOpenFL";
	private static var TASK_SETUP_OPENFL = "setupOpenFL";
	
	private var urlLoader:URLLoader;
	
	
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
		
	}
	
	
	private function installHaxe ():Void {
		
		var url = switch (PlatformHelper.hostPlatform) {
			
			case WINDOWS: "http://haxe.org/website-content/downloads/3.2.1/downloads/haxe-3.2.1-win.exe";
			case MAC: "http://haxe.org/website-content/downloads/3.2.1/downloads/haxe-3.2.1-osx-installer.pkg";
			default: "http://www.openfl.org/builds/haxe/haxe-3.2.1-linux-installer.tar.gz";
			
		}
		
		urlLoader = new URLLoader ();
		urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
		urlLoader.addEventListener (Event.COMPLETE, function (_) {
			
			StatusText.text = "Installing Haxe";
			
			Actuate.timer (0.1).onComplete (function () {
				
				var file = Path.withoutDirectory (url);
				File.saveBytes (file, urlLoader.data);
				
				switch (PlatformHelper.hostPlatform) {
					
					case WINDOWS: Sys.command (file);
					case MAC: Sys.command ("open", [ file ]);
					default: Sys.command ("xdg-open", [ file ]);
					
				}
				
				TaskManager.completeTask (TASK_INSTALL_HAXE);
				
				//FileSystem.deleteFile (file);
				
			});
			
		});
		urlLoader.addEventListener (ProgressEvent.PROGRESS, function (event) {
			
			StatusText.text = "Downloading Haxe... (" + Std.int ((event.bytesLoaded / event.bytesTotal) * 100) + "%)";
			
		});
		urlLoader.load (new URLRequest (url));
		
	}
	
	
	private function installLime ():Void {
		
		var url = "http://www.openfl.org/builds/lime/lime-2.7.0.zip";
		
		urlLoader = new URLLoader ();
		urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
		urlLoader.addEventListener (Event.COMPLETE, function (_) {
			
			StatusText.text = "Installing Lime";
			
			Actuate.timer (0.1).onComplete (function () {
				
				var file = "lime.zip";
				File.saveBytes (file, urlLoader.data);
				Sys.command ("haxelib", [ "local", "lime.zip" ]);
				
				TaskManager.completeTask (TASK_INSTALL_LIME);
				
				//FileSystem.deleteFile (file);
				
			});
			
		});
		urlLoader.addEventListener (ProgressEvent.PROGRESS, function (event) {
			
			StatusText.text = "Downloading Lime... (" + Std.int ((event.bytesLoaded / event.bytesTotal) * 100) + "%)";
			
		});
		urlLoader.load (new URLRequest (url));
		
	}
	
	
	private function installOpenFL ():Void {
		
		var url = "http://lib.haxe.org/p/openfl/3.4.0/download/";
		
		urlLoader = new URLLoader ();
		urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
		urlLoader.addEventListener (Event.COMPLETE, function (_) {
			
			StatusText.text = "Installing OpenFL";
			
			Actuate.timer (0.1).onComplete (function () {
				
				var file = "openfl.zip";
				File.saveBytes (file, urlLoader.data);
				Sys.command ("haxelib", [ "local", "openfl.zip" ]);
				
				TaskManager.completeTask (TASK_INSTALL_OPENFL);
				
				//FileSystem.deleteFile (file);
				
			});
			
		});
		urlLoader.addEventListener (ProgressEvent.PROGRESS, function (event) {
			
			StatusText.text = "Downloading OpenFL... (" + Std.int ((event.bytesLoaded / event.bytesTotal) * 100) + "%)";
			
		});
		urlLoader.load (new URLRequest (url));
		
	}
	
	
	private function setupOpenFL ():Void {
		
		StatusText.text = "Setting up OpenFL...";
		Sys.command ("haxelib", [ "run", "openfl", "setup", "-y" ]);
		StatusText.text = "Done!";
		
	}
	
	
	
	
	// Event Handlers
	
	
	
	
	private function InstallButton_onMouseDown (event:MouseEvent):Void {
		
		InstallButton.mouseEnabled = false;
		Actuate.tween (InstallButton, 2, { alpha: 0 } );
		Actuate.tween (StatusText, 2, { alpha: 1 } );
		
		TaskManager.addTask (new Task (TASK_INSTALL_HAXE, installHaxe), null, false);
		TaskManager.addTask (new Task (TASK_INSTALL_LIME, installLime), [ TASK_INSTALL_HAXE ], false);
		TaskManager.addTask (new Task (TASK_INSTALL_OPENFL, installOpenFL), [ TASK_INSTALL_LIME ], false);
		TaskManager.addTask (new Task (TASK_SETUP_OPENFL, setupOpenFL), [ TASK_INSTALL_OPENFL ]);
		
	}
	
	
}