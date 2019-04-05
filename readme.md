# Auto Armory 
*An Armory / Rift-Type changing script for ros-bot*

## About
* Script by: **djpurpose**
* Made possible by **RoSBot** and **RBAssist**
* Questions or suggestions I can be reached on Discord: `djpurpose#9880`
* This script is use at your own risk but if you follow the setup you should be fine.

## Version updates
* v0.01 - 04/01/2019 - Initial build.
* v0.02 - 04/02/2019 - Changed gear change verification to offhand instead of skills to be compatible with TurboHUD. Removed 5rift/6grift rift type and added 2rift/4grift. 2/4 is the same ratio of 1/2 with less gear changes but I left 1/2 for faster testing.
* v0.03 - 04/03/2019 - Added support for the edge case where activating the RBAssist window fails. Now we wait 10 sec for it to become active and continue on to try again after the next rift.
* v0.04 - 04/03/2019 - Added additional gear verification to be safe. We now check the quiver and the main attack (right mouse button.) Also added hotkeys to increment `Ctrl + >` or decrement `Ctrl + <` rift count. This allows you to add to the rift count to switch gear next time you are in town or decrement rift count if you want to run a couple more grifts and use up your pools.
* v0.05 - 04/04/2019 - Added autoArmoryTest.ext and it's source. This allows the user to test out swapping gear without running rifts. It also will swap the rift type in rosbot so run it with rosbot open (but not running) and d3 open. Just press Ctrl+g to change gear. Note there's a 6 sec delay once pressing till it tries to swap gear. 

## How it Works
1. Run the number of rifts specified.
2. Change armory / rift type
3. Run the number of grifts specified.
4. Change armory /rift type
5. Go to number step 1

## Requirements
1. This script
2. [rosbot](www.ros-bot.com) with premium license (for master profile)
3. [RBAssist - Bot Scheduling and Crash Recovery](https://www.ros-bot.com/forums/general-discussion/rbassist-bot-scheduling-and-crash-recovery-1376373)
4. Diablo 3 running on fast PC (not sure this would work in a vm without modification). Windows should be 1920x1080. Diablo should be run windowed at minimum size (h and w) as the script assumes that size for clicking the correct coordinates.
5. Running MultiShot / Impale Demon Hunter (can run other classes/builds with modifications)
6. The script now supports TurboHUD. If you want to use TurboHUD add a trigger to RBAssist to launch your TurboHUD executable when launching D3. Its not required and should speed things up if you don't use it but it will provide exp/hr stats for you which is nice. To use it I normally have RBA load diablo and RoSBot then once the Diablo Start Game screen is up I click on the autoArmory exe. If you are not in your rift gear or the bot is not set to do regualr rifts only then press F7 to stop the bot, change those and start the bot again.
7. Default mapping for map (should be `m`) and Esc should be Esc.

## What you should see
1. After running the correct number of rifts and finishing vendor loop it should stop the bot and wait.
2. Next, (assuming you set your town to act 1) it should open the map and teleport to **Old Ruins**.
3. After that it should click the teleporter and select act 1 town.
4. It should then click on the armory to walk over and open it up.
5. Next it clicks either tab 1 for rifts or tab 2 for grifts and clicks equip.
6. Next it does an image search to verify we changed correctly.
7. Once its sure its in the right gear it changes the config in the bot to the correct rift type and and stop/starts the RBAssist monitor to resume botting.
8. If the gear change failed we don't change the bot rift type and we run another one. After the end of that rift/grift it should re-try to change gear.


## Optional
1. [Autoit](https://www.autoitscript.com/cgi-bin/getfile.pl?autoit3/autoit-v3-setup.exe) 
2. [AutoIt Script Editor](https://www.autoitscript.com/site/autoit-script-editor/downloads/) for modifying the script. 

## How to Run
1. Make sure the entire "Setup / Install" is complete before starting.
2. Start Diablo 3 and change into your rift gear (armory 1)
3. Start RoS Bot and make sure DoGreaterRift is false, we always start in rift mode.
4. Start RBAssist.
5. Start autoArmory.exe in administrator mode (needed to control windows, mouse, keyboard). The script should detect the Diablo III window and activate it. If Diablo is not running the script will throw an error so make sure it's running before launching the script. 
6. The script should show in your taskbar. If you need to close the script you can right click the icon and click exit.
7. Once the script is running, click "Start" in RBAssist.
8. Hopefully you now have a working armory switcher. 


## Suggestions
1. Run the 1/2 script first (it might be the best fit anyways depending on your gear) then monitor the the bot. It should stop after the first successful rift and change gear / rift settings. **WARNING** Avoid using the mouse/keyboard at all costs when its changing gear. Any slight input can make it fail. 

2. If you are tech-savy I suggest installing the tail command into windows and doing a tail - f on the ArmoryLog.txt and showing on your screen, this can help debug any issues you might have. See screenshot:

 ![](readmeImages/tail.PNG)



## Setup / Install
1. Click the "Clone or Download" button then "Download Zip"
2. Extract the zip to a directory of your choice. 
3. Run Diablo III in windowed mode and make the window the minimum size (it will not work any larger than this without modification). To be safe run windows in 1920x1080. Will work on supporting other resolutions and window sizes.
4. Make sure your Rift gear is in Armory 1 (Multishot using Dead Mans Legacy quiver, we will detect this later). Make sure no items are missing. Also Multishot should be on the right mouse button as shown.

 ![](readmeImages/Armory1.PNG)

5. Make sure your GRift gear is in Armory 2 (Impale using Holy Point Shot, we will detect this later). Make sure no items are missing. Also Impale should be on the right mouse button as shown.

 ![](readmeImages/Armory2.PNG)

6. Setup your Master Profile. Like shown. The purpose of these settings is to make sure there is no possible way to lose gems when changing gear. Vendor limit: 24 Items and a picket that doesn't sell gems.

  **To test:** Put a legendary gem and a flawless royal gem you don't care about in your inventory and run some rifts. If the bot correctly puts the gems in your stash then you should be good to go. 

  **NOTE:** In over a week of testing I never had an issue losing anything. The script only changes armory and restarts the bot. As long as your bot settings are correct you shouldn't have any trouble.

 ![](readmeImages/MasterProfile.PNG)

7. Assuming you have RBAssist setup already. In RBAssist General tab set "Start RoS-Bot when monitoring starts"

 ![](readmeImages/RBAMain.PNG)

8. In RBAssist Monitoring tab set the following:

 ![](readmeImages/RBAMonitoring.PNG)

9. In RBAssist Triggers tab set the following Trigger/Actions Note that's `^[` and `^]` for the keystrokes to send:

 ![](readmeImages/RBATriggers.PNG)
 ![](readmeImages/RBATriggers2.PNG)

10. In RoS Bot make sure to set your master profile, and rift as the Sequence:

 ![](readmeImages/RosBot.PNG)

11. In RoS Bot Config set the following settings. Note we always start the session in Rift mode so set DoGreaterRift to False:

 ![](readmeImages/RosBotConfig.PNG)

## Troubleshooting
1. Subscript Error when loading script: The Diablo window is not open. Open Diablo before opeing the script

2. Doesnt change gear correctly. Most likely your window size is off or the timers are too short for your PC speed. Look at the logs to see where you you need to adjust.

3. Script is running a gr as multishot or a rift as impale. Can be a few things:
   1. You didn't start things correctly, make sure you are wearing rift gear (multishot armory 1), make sure rosbot is set to not run grifts, exit any running autoArmory scripts and start a fresh one. This insures we are in the correct state when starting.

   2.  It might have changed gear ok but failed to change the rift type. Watch it closely to see where it failed.
