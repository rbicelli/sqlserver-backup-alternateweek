[![Buy Me A Coffee](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/rbicelli)

# sqlserver-backup-alternateweek
These are T-SQL scripts for backing up SQL Server with its standard methods.

## How it Works
The scripts are responsible to take SQL Server backups, alternating backup sets for odd and even week:

```
	SUNDAY        MONDAY       TUESDAY       WEDNESDAY       THURSDAY       FRIDAY       SATURDAY
	[Full]  --->  [Diff]  -->  [Diff]   -->   [Diff]    -->   [Diff]   -->  [Diff]  -->   [Diff]
  (Flip Set)
```
The script creates one .bak file per database per set. With Databases in Full Recovery Model it creates also a .trn file per database per set. 

## Compatibility
Any SQL Server Version (Tested from SQL Server 2008 R2 to SQL Server 2017).
SQL Server Express is also compatible.

## Usage
Grab the SQL scripts.

Schedule as this, with Windows Task Scheduler or SQL Server Agent:

- Full backup the first day of week (Sunday)
- At least one differential backup other days, excluding the first day of week
- If you run databases in Full Recovery Model schedule the Transactions log backup suiting your needs (it is advisable to frequently backup T-Logs)

For each script, edit the parameters sections, according to your setup.
Change backup path and 

```
-- SET PARAMETERS HERE
SET @BackupPath = '\\YOURSERVER\YOURSHARE\YOURFOLDER\'
@OddSetName = 'SET-ODD'
@EvenSetname = 'SET-EVEN'
-- END SET PARAMS
```

Then create **\\YOURSERVER\YOURSHARE\YOURFOLDER\SET-ODD** and **\\YOURSERVER\YOURSHARE\YOURFOLDER\SET-EVEN**

## Exclude database from backup
If you need to exclude databases from backup simply edit the scripts at point when it opens cursor:

```
-- Exclude system databases from backup
DECLARE db_cursor CURSOR FOR  
SELECT name 
FROM master.sys.databases 
WHERE name NOT IN ('master','model','msdb','tempdb','ReportServerTempDB')
```