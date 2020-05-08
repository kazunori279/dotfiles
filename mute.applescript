(*

AppleScript to toggle Sound input volume between 0 and 0.5 with a global shortcut key.

How to use: 
- To add a shortcut key: Use Apple Automator to create a new Quick Action and select Library > Utilities > Run AppleScript 
and paste this code. Then open System Preferences > Keyboard > Shortcuts > Services so you can find the action 
and specify a shortcut key.
- On the first run, you'll be asked to add an accessibility setting for each app such as Chrome.
- (Option) You can also specify the defaultInput_ property to set your preferred input device 

*)

-- consts
property defaultVolume_ : 0.5
property defaultInput_ : "*** YOUR AUDIO INPUT DEVICE NAME ***"

-- save the front app name
tell application "System Events"
	set frontApp to (path to frontmost application) as text
end tell

-- activate Sound pane
tell application "System Preferences"
	activate
	set current pane to pane "Sound"
end tell

-- select Input tab
repeat
	try
		tell application "System Events"
			tell radio button "Input" of tab group 1 of window "Sound" of process "System Preferences"
				click
			end tell
		end tell
		exit repeat
	on error errMsg
		"Retrying.."
	end try
end repeat

tell application "System Events"
	
	-- select the default sound input
	repeat with r in rows of table 1 of scroll area 1 of tab group 1 of window "Sound" of process "System Preferences"
		set input to value of text field 1 of r
		if input = defaultInput_ then
			select r
		end if
	end repeat
	
	-- set volume to 0 or defaultVolume_
	tell slider "Input volume:" of group 2 of tab group 1 of window "Sound" of process "System Preferences"
		if value > 0 then
			set defaultVolume_ to value
			set value to 0
		else
			set value to defaultVolume_
		end if
	end tell
end tell

-- activate the original front app
activate application frontApp
