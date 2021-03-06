----------------------------------------------------------------
----------------------------------------------------------------
-- Enfuse droplet applescript 0.0.3
-- Harry van der wolf 29 Apr 2008
----------------------------------------------------------------
----------------------------------------------------------------
on FUNC_ABOUT()
	display dialog "Enfuse droplet 0.0.2 by Harry van der Wolf" & return & return & ?
		"This (G)UI wrapper uses enfuse and align_image_stack " & ?
		"to fuse your set of images with different exposure " & ?
		"settings to one fused image." & return & return & ?
		"You can use this GUI either by starting it " & ?
		"manually and then select your images" & ?
		return & return & "OR" & return & return & ?
		"drag and drop your images onto this little application." buttons {"Ok"}
	
end FUNC_ABOUT
----------------------------------------------------------------
----------------------------------------------------------------
on FUNC_Initialize_BP_PGB(titlebarmsg, topmsg, bottommsg)
	tell application "BP Progress Bar"
		launch
		set title of window 1 to titlebarmsg
		activate
		show window 1
		tell window 1 of application "BP Progress Bar"
			tell progress indicator 1
				set indeterminate to true
				start
			end tell
		end tell
		tell window 1 of application "BP Progress Bar" to tell text field 1 to set content to topmsg
		tell window 1 of application "BP Progress Bar" to tell text field 2 to set content to bottommsg
	end tell
end FUNC_Initialize_BP_PGB
----------------------------------------------------------------
----------------------------------------------------------------
on FUNC_quit_BP_PGB()
	tell application "BP Progress Bar" to quit
end FUNC_quit_BP_PGB
----------------------------------------------------------------
----------------------------------------------------------------
-- function enfuse
on FUNC_ENFUSE(dropped_on, ImageList)
	
	
	-- set enfuse_additional_parameters to "--wExposure=1 --wSaturation=1 --wContrast=1"
	set enfuse_additional_parameters to ""
	---- start images selection if dropped_on is false
	if not dropped_on then
		set ImageList to ""
		set theImages to ?
			choose file with prompt ?
				"Select the image files of your choice" default location (path to pictures folder) ?
				of type {"JPEG", "TIFF", "PNG"} with multiple selections allowed without invisibles
		repeat with OneImage in theImages
			set OneImage to quoted form of POSIX path of OneImage
			set testname to POSIX path of OneImage
			-- we need this extension later
			if (testname as text) ends with ".TIF" or (testname as text) ends with ".TIFF" then
				set ImgExt to ".tif"
			else
				set ImgExt to ".jpg"
			end if
			
			set ImagePath to quoted form of POSIX path of OneImage --should do it only once but who cares
			set ImageList to ImageList & OneImage & " "
		end repeat
		---- end of images selection
	end if
	
	-- Find the working dir of the program, otherwise it will default to $HOME where ais and enfuse are not available
	tell application "Finder" to get folder of (path to me) as Unicode text
	set workingDir to POSIX path of result
	
	-- delete possible previous fused intermediate images (normally overwritten?
	-- when there are more images from a previous run than need to be calculated, you get strange images
	--tell application "Finder"
	try -- use try to not display (error) dialog on non existing files
		do shell script "rm " & workingDir & "fused*.tif"
	end try
	--end tell
	
	
	---- kick off align_image_stack and set barber pole
	FUNC_Initialize_BP_PGB("Running align_image_stack", "Align_image_stack is aligning your images", "This will take some time. Please wait....")
	do shell script "cd " & workingDir & "; " & workingDir & "align_image_stack" & " -a fused " & " " & ImageList
	FUNC_quit_BP_PGB()
	---- align_image_stack finished. stop barber pole
	
	----Ask filename of fused image and where it should be stored
	set NewImgName to (choose file name with prompt "Specify the filename of your new fused image" default location (path to pictures folder))
	set NewImage to quoted form of POSIX path of NewImgName
	set testname to POSIX path of NewImgName
	-- file extensions are not treated case-sensitive within applescript
	if (testname as text) ends with ".TIF" or (testname as text) ends with ".JPG" or (testname as text) ends with ".TIFF" or (testname as text) ends with ".JPEG" then
		set NewImage to quoted form of POSIX path of testname
		--display dialog NewImage
	else
		-- No image extension, so make it a tif
		set testname to testname & ".tif"
		set NewImage to quoted form of POSIX path of testname
		--display dialog NewImage
	end if
	---- kick off enfuse and set barber pole
	FUNC_Initialize_BP_PGB("Running enfuse", "enfuse is merging your images", "This will take some time. Please wait....")
	do shell script "cd " & workingDir & "; " & workingDir & "enfuse " & " -o " & NewImage & " " & workingDir & "fused*.tif"
	FUNC_quit_BP_PGB()
	---- enfuse finished. stop barber pole
	
	---- Show fused image to the public
	-- Stupid preview application is not scriptable so we need to shell out.
	-- Next to that there is another stupidity: It's called Preview.app on Tiger and preview.app on Leopard.
	do shell script "open /Applications/Preview.app " & NewImage
	do shell script "open /Applications/preview.app " & NewImage
	
end FUNC_ENFUSE
-- end of function enfuse
----------------------------------------------------------------
----------------------------------------------------------------


-- Main part of script
-- Here does it all start
-- Define some (initial) variables/properties
global ImageList
set ImageList to ""

-- "open" handler triggered by drag'n'drop launch.
-- This parts starts when a user drops files on it
on open of finderObjects
	global HUGIN_PATH
	--set HUGIN_PATH to "/Applications/Hugin.app"
	set HUGIN_PATH to ""
	set ImageList to ""
	repeat with OneImage in (finderObjects) -- in case multiple objects dropped on applet
		--set pipo to quoted form of POSIX path of i as text
		--display dialog pipo -- show file/folder's info
		if folder of (info for OneImage) is true then -- process folder's contents too
			repeat with OneImage in finderObjects
				set OneImage to quoted form of POSIX path of OneImage
				set testname to POSIX path of NewImgName
				-- we need this extension later
				if (testname as text) ends with ".TIF" or (testname as text) ends with ".TIFF" then
					set ImgExt to ".tif"
				else
					set ImgExt to ".jpg"
				end if
				set ImagePath to quoted form of POSIX path of OneImage --should do it only once but who cares
				set ImageList to ImageList & OneImage & " "
			end repeat
		end if
		--		repeat with OneImage in finderObjects
		set OneImage to quoted form of POSIX path of OneImage
		set ImagePath to quoted form of POSIX path of OneImage --should do it only once but who cares
		set ImageList to ImageList & OneImage & " "
		--		end repeat
	end repeat
	-- run function enfuse
	set dropped_on to true
	FUNC_ENFUSE(dropped_on, ImageList)
end open
-- end of drag'n'drop launch

-- This is the part that starts when user opens application by double-clicking it

set ImageList to ""
-- ask user what he/she wants
set quit_app to false
repeat until quit_app is true
	display dialog "Click Enfuse to get going!" buttons {"about", "quit", "Enfuse"} default button "Enfuse"
	set choice to button returned of result
	if choice = "Enfuse" then
		set dropped_on to false
		FUNC_ENFUSE(dropped_on, ImageList)
	else if choice = "about" then
		FUNC_ABOUT()
	else
		return --user has chosen quit so quit script
	end if
end repeat
end run