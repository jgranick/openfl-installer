package;


import haxe.io.Path;
import haxe.macro.Compiler;
import lime.project.Haxelib;
import lime.project.Platform;
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
		
		StatusText.text = "Running Haxe Installer (" + Compiler.getDefine ("HAXE_VERSION") + ")...";
		
		Actuate.timer (1.2).onComplete (function () {
			
			var path = PathHelper.getTemporaryDirectory ();
			PathHelper.mkdir (path);
			
			switch (PlatformHelper.hostPlatform) {
				
				case WINDOWS: path = PathHelper.combine (path, "haxe-" + Compiler.getDefine ("HAXE_VERSION") + "-win.exe");
				case MAC: path = PathHelper.combine (path, "haxe-" + Compiler.getDefine ("HAXE_VERSION") + "-osx-installer.pkg");
				default:
				
			}
			
			File.saveBytes (path, Assets.getBytes ("haxe"));
			
			switch (PlatformHelper.hostPlatform) {
				
				case WINDOWS: runProcess (path);
				case MAC: runProcess ("open", [ path ]);
				default: runProcess ("xdg-open", [ path ]);
				
			}
			
			PathHelper.removeDirectory (Path.directory (path));
			TaskManager.completeTask ("installHaxe");
			
		});
		
	}
	
	
	private function installHaxelib (name:String, key:String, segmentCount:Int = 1, version:String = "1.0.0"):Void {
		
		StatusText.text = "Installing " + name + " (" + version + ")...";
		
		var path = PathHelper.getTemporaryFile (".zip");
		var output = File.write (path);
		
		if (segmentCount < 2) {
			
			output.write (Assets.getBytes (key));
			
		} else {
			
			for (i in 0...segmentCount) {
				
				output.write (Assets.getBytes (key + ".segment" + i));
				
			}
			
		}
		
		output.close ();
		
		var worker = new BackgroundWorker ();
		worker.doWork.add (function (_) {
			
			runProcess ("haxelib", [ "local", path ]);
			worker.sendComplete ();
			
		});
		
		worker.onComplete.add (function (_) {
			
			try {
				
				FileSystem.deleteFile (path);
				
			} catch (e:Dynamic) { }
			
			TaskManager.completeTask ("install" + name);
			
		});
		
		worker.run ();
		
	}
	
	
	private function runProcess (command:String, args:Array<String> = null):String {
		
		if (args == null) args = [];
		
		return switch (PlatformHelper.hostPlatform) {
			
			case WINDOWS: ProcessHelper.runProcess ("", "cmd", [ "/c", command ].concat (args), true, true, true);
			default: ProcessHelper.runProcess ("", command, args, true, true, true);
			
		}
		
	}
	
	
	private function setupOpenFL ():Void {
		
		StatusText.text = "Installing \"openfl\" Command...";
		
		var worker = new BackgroundWorker ();
		worker.doWork.add (function (_) {
			
			var haxePath = Sys.getEnv ("HAXEPATH");
			
			if (PlatformHelper.hostPlatform == Platform.WINDOWS) {
				
				if (haxePath == null || haxePath == "") {
					
					haxePath = "C:\\HaxeToolkit\\haxe\\";
					
				}
				
				try { File.copy (PathHelper.getHaxelib (new Haxelib ("lime")) + "\\templates\\\\bin\\lime.exe", haxePath + "\\lime.exe"); } catch (e:Dynamic) {}
				try { File.copy (PathHelper.getHaxelib (new Haxelib ("lime")) + "\\templates\\\\bin\\lime.sh", haxePath + "\\lime"); } catch (e:Dynamic) {}
				try { File.copy (PathHelper.getHaxelib (new Haxelib ("openfl")) + "\\templates\\\\bin\\openfl.exe", haxePath + "\\openfl.exe"); } catch (e:Dynamic) {}
				try { File.copy (PathHelper.getHaxelib (new Haxelib ("openfl")) + "\\templates\\\\bin\\openfl.sh", haxePath + "\\openfl"); } catch (e:Dynamic) {}
				
			} else {
				
				try {
					
					ProcessHelper.runCommand ("", "sudo", [ "cp", "-f", PathHelper.getHaxelib (new Haxelib ("lime")) + "/templates/bin/lime.sh", "/usr/local/bin/lime" ], false);
					ProcessHelper.runCommand ("", "sudo", [ "chmod", "755", "/usr/local/bin/lime" ], false);
					ProcessHelper.runCommand ("", "sudo", [ "cp", "-f", PathHelper.getHaxelib (new Haxelib ("openfl")) + "/templates/bin/openfl.sh", "/usr/local/bin/openfl" ], false);
					ProcessHelper.runCommand ("", "sudo", [ "chmod", "755", "/usr/local/bin/openfl" ], false);
					
				} catch (e:Dynamic) {}
				
			}
			
			worker.sendComplete ();
			
		});
		worker.onComplete.add (function (_) {
			
			StatusText.text = "Done!";
			
			TaskManager.completeTask ("setupOpenFL");
			
		});
		worker.run ();
		
	}
	
	
	
	
	// Event Handlers
	
	
	
	
	private function InstallButton_onMouseDown (event:MouseEvent):Void {
		
		InstallButton.mouseEnabled = false;
		Actuate.tween (InstallButton, 2, { alpha: 0 } );
		Actuate.tween (StatusText, 2, { alpha: 1 } );
		
		var installHaxeTask = new Task ("installHaxe", installHaxe);
		TaskManager.addTask (installHaxeTask, null, false);
		var previousTask = installHaxeTask;
		
		var names = [ "Lime", "OpenFL", "SWF", "HXCPP", "Actuate", "Box2D", "Layout", "OpenFL Samples", "Lime Samples" ];
		var keys = [ "lime", "openfl", "swf", "hxcpp", "actuate", "box2d", "layout", "openfl-samples", "lime-samples" ];
		var segments = [ Std.parseInt (Compiler.getDefine ("LIME_SEGMENT_COUNT")), Std.parseInt (Compiler.getDefine ("OPENFL_SEGMENT_COUNT")), Std.parseInt (Compiler.getDefine ("SWF_SEGMENT_COUNT")), Std.parseInt (Compiler.getDefine ("HXCPP_SEGMENT_COUNT")), Std.parseInt (Compiler.getDefine ("ACTUATE_SEGMENT_COUNT")), Std.parseInt (Compiler.getDefine ("BOX2D_SEGMENT_COUNT")), Std.parseInt (Compiler.getDefine ("LAYOUT_SEGMENT_COUNT")), Std.parseInt (Compiler.getDefine ("OPENFL_SAMPLES_SEGMENT_COUNT")), Std.parseInt (Compiler.getDefine ("LIME_SAMPLES_SEGMENT_COUNT")) ];
		var versions = [ Compiler.getDefine ("LIME_VERSION"), Compiler.getDefine ("OPENFL_VERSION"), Compiler.getDefine ("SWF_VERSION"), Compiler.getDefine ("HXCPP_VERSION"), Compiler.getDefine ("ACTUATE_VERSION"), Compiler.getDefine ("BOX2D_VERSION"), Compiler.getDefine ("LAYOUT_VERSION"), Compiler.getDefine ("OPENFL_SAMPLES_VERSION"), Compiler.getDefine ("LIME_SAMPLES_VERSION") ];
		
		var task;
		
		for (i in 0...names.length) {
			
			task = new Task ("install" + names[i], installHaxelib, [ names[i], keys[i], segments[i], versions[i] ]);
			TaskManager.addTask (task, [ previousTask ], false);
			previousTask = task;
			
		}
		
		TaskManager.addTask (new Task ("setupOpenFL", setupOpenFL), [ previousTask ], false);
		
	}
	
	
}