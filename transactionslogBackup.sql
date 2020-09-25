-- SQL SERVER BACKUP LOG WITH ODD/EVEN WEEK ROTATION
-- (c) 2016-2020 Riccardo Bicelli <r.bicelli@gmail.com>
-- VERSION 1.0
-- REQUIRED VARIABLES
DECLARE 
      @EvenOdd INT,
      @BackupSet VARCHAR(20),
      @BackupFile VARCHAR(128),
      @BackupName VARCHAR(128),
      @DBName VARCHAR(128),
      @BackupPath VARCHAR(256),
      @OddSetName VARCHAR(32),
      @EvenSetName VARCHAR(32)
    
-- SET PARAMETERS HERE
SET @BackupPath = '\\YOURSERVER\YOURSHARE\YOURFOLDER\'
@OddSetName = 'SET-ODD'
@EvenSetname = 'SET-EVEN'
-- END SET PARAMS

DECLARE @ErrExec TINYINT
SET @ErrExec = 0

SET @EvenOdd=datepart(wk, CAST(GETDATE() AS DATE)) % 2 
IF @EvenOdd = 0 SET @BackupSet=@EvenSetName ELSE SET @BackupSet=@OddSetName

-- Open cursor, change the list of excluded databases according to your needs
DECLARE db_cursor CURSOR FOR  
SELECT name
FROM master.sys.databases 
WHERE name NOT IN ('master','model','msdb','tempdb','ReportServerTempDB') 
AND recovery_model <> 3 

OPEN db_cursor   
FETCH NEXT FROM db_cursor INTO @DBName   

WHILE @@FETCH_STATUS = 0   
BEGIN   
       
       --Transaction Log Backup
       SET @BackupFile = @BackupPath + '\' + @BackupSet + '\' +  @DBName + '.TRN'
       SET @BackupName = N'Backup Transaction Logs of ' + @DBName + ' (' + @BackupSet + ')'

       -- In order not to exit the whole step if only one backup fails let’s include
       -- operations in this try/catch statement
       BEGIN TRY
           BACKUP LOG @DBName
           TO DISK = @BackupFile WITH NOFORMAT, NOINIT,  
           NAME = @BackupName,
           DESCRIPTION = 'Transaction Log Backup'
       END TRY
       BEGIN CATCH  
          -- If an error is caught, Write a message to Windows Event Log and set @ErrExec
          -- Variable to a value greater than zero      
          DECLARE @ErrorDescr nvarchar(128)
          SET @ErrorDescr = N'Error During Transaction Log Backup of Database ' + @DBName           
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
	RAISERROR('Backup Transaction Log threw an exception', 20, 1) WITH LOG;
END

GO