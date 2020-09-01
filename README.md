# AD Snapshot rotation script
* This script creates and rotates AD snapshots. It also automatically removes all snapshots except those containing NTDS DB (by default Windows creates snapshots for all disks which can be sub-optimal if your NTDS DB is stored on a separate drive or DC simply has more than one drive). 
* It also sends reports on currently stored snapshots to specified email after each execution. 
* Parameters like max age, DC name, NTDS drive and email can be customized through variables. 
* The whole script is wrapped in ScriptBlock which will be executed on the specified DC. 
* The script itself can be scheduled to run on any server that can reach DC via WinRM.
NOTE: I wrote and used this script before learning about a similar script https://gallery.technet.microsoft.com/scriptcenter/Script-to-create-Active-2d389218 which is a better and cleaner option since it uses WMI instead of ntdsutil.
