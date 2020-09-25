-- SQL SERVER BACKUP LOG WITH ODD/EVEN WEEK ROTATION
-- (c) 2016-2020 Riccardo Bicelli <r.bicelli@gmail.com>
-- VERSION 1.0
-- FULL BACKUP

DECLARE 
	@EvenOdd INT,
	@BackupSet VARCHAR(20),
	@BackupFile VARCHAR(128),
	@MediaName VARCHAR(128),
	@BackupName VARCHAR(128),
	@DBName VARCHAR(128),
	@BackupPath VARCHAR(256),
	@OddSetName VARCHAR(32),
    @EvenSetName VARCHAR(32)
    
-- SET PARAMETERS HERE
SET @BackupPath = '\\YOURSERVER\YOURSHARE\YOURFOLDER\'
SET @OddSetName = 'SET-ODD'
SET @EvenSetname = 'SET-EVEN' 
-- END PARAMS

DECLARE @ErrExec TINYINT
SET @ErrExec = 0

-- Check if Current Week is odd or even
SET @EvenOdd=datepart(wk, CAST(GETDATE() AS DATE)) % 2 
IF @EvenOdd = 0 SET @BackupSet=@EvenSetName ELSE SET @BackupSet=@OddSetName

-- Exclude system databases from backup
DECLARE db_cursor CURSOR FOR  
SELECT name 
FROM master.sys.databases 
WHERE name NOT IN ('master','model','msdb','tempdb','ReportServerTempDB') 

OPEN db_cursor   
FETCH NEXT FROM db_cursor INTO @DBName   

WHILE @@FETCH_STATUS = 0   
BEGIN   
       SET @BackupFile = @BackupPath + @BackupSet + '\' +  @DBName + '.bak'
       SET @MediaName = @DBName + '_FullBackup_' + @BackupSet
       SET @BackupName = N'Backup Database ' + @DBName + ' (' + @BackupSet + ')'
       
       -- Encapsulate the backup block in a try/catch statement, so a single failed backup
       -- doesn't stop the entire job
       BEGIN TRY
	      BACKUP DATABASE @DBName
	      TO DISK = @BackupFile
           WITH INIT, FORMAT,
           MEDIANAME = @MediaName,
           NAME = @BackupName
       END TRY
       BEGIN CATCH
            -- Can't backup database, log error to eventviewer
            DECLARE @ErrorDescr nvarchar(128)
            SET @ErrorDescr = N'Error During Full Backup of Database ' + @DBName
            EXEC xp_logevent 50001, @ErrorDescr, warning;
            SET @ErrExec = 1
       END CATCH

       FETCH NEXT FROM db_cursor INTO @DBName   
END   

CLOSE db_cursor   
DEALLOCATE db_cursor

-- If some errors encountered, exit step with an error.
IF @ErrExec > 0
BEGIN
	RAISERROR('Full Backup threw an exception', 20, 1) WITH LOG;
END

GO