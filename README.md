# SALTY FRONT

## Folder Structure
**/bgm** - Contains BGM music files, in OGG format, IGNORED IN REPO  
**/data** - General data folder, contains misc data files  
**/data/parts** - Data files for mech parts  
**/data/records** - Files written to record stats, IGNORED IN REPO  
**/data/user** - Data files for user and pilot data, IGNORED IN REPO  
**/godot** - Contains project source files and configuration file  
**/screenshot** - Write destination for screenshots

## Key Files
**/godot/settings.cfg** - Game settings  

## .gitignore
data/records/  
data/user/  
bgm/  
screenshot/  
godot/settings.cfg  

## Config file
### paths - File paths for assets and data
bgm="../bgm/"  
data="../data/"  
parts="../data/parts/"  
recs="../data/records/"  
user="../data/user/"  

### flags - Game state flags for testing
offline_mode=true  
fast_wait=true  
fast_combat=true  

### game - Game wait time settings (seconds)
prep_time=60  
prep_time_fast=4  
pay_time=30  
pay_time_fast=2  
bet_time=60  
bet_time_fast=2  

### map - Map/Arena settings
turn_timeout=60  
idle_timeout=30  

### mech - Mech settings, time in seconds
move_speed=10.0  
move_speed_fast=20.0  
anim_speed=1.0  
anim_speed_fast=1.5  
wait_time=0.25  
wait_time_fast=0.15  