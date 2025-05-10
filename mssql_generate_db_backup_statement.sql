DECLARE @DatabaseName NVARCHAR(128)
DECLARE @BackupPath NVARCHAR(260)
DECLARE @FullBackupName NVARCHAR(260)
DECLARE @LogBackupName NVARCHAR(260)
DECLARE @DateTimeStamp NVARCHAR(20)
DECLARE @FSQL NVARCHAR(MAX)
DECLARE @TLSQL NVARCHAR(MAX)

-- Set the backup path
SET @BackupPath = 'C:\BackupFolder\' -- Specify the desired backup path

-- Generate a timestamp to append to the backup file names
SET @DateTimeStamp = REPLACE(REPLACE(CONVERT(NVARCHAR, GETDATE(), 120), '-', ''), ' ', '_')
SET @DateTimeStamp = REPLACE(REPLACE(REPLACE(REPLACE(@DateTimeStamp, ':', ''), '.', ''), '_', ''), '-', '')

-- Create a cursor to loop through user databases
DECLARE DatabaseCursor CURSOR FOR
SELECT name
FROM sys.databases
WHERE database_id > 4 -- Exclude system databases

OPEN DatabaseCursor
FETCH NEXT FROM DatabaseCursor INTO @DatabaseName

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Generate the backup file names
    SET @FullBackupName = @BackupPath + @DatabaseName + '_FullBackupCopyOnly_' + @DateTimeStamp + '.bak'
    SET @LogBackupName = @BackupPath + @DatabaseName + '_LogBackupCopyOnly_' + @DateTimeStamp + '_log.trn'

    -- Create a full database backup
    SELECT @FSQL = 'BACKUP DATABASE [' + @DatabaseName + '] TO DISK = N''' + @FullBackupName + ''' WITH COPY_ONLY, NOFORMAT, NOINIT'
    PRINT (@FSQL)

    -- Create a transaction log backup
    SELECT @TLSQL = 'BACKUP LOG [' + @DatabaseName + '] TO DISK = N''' + @LogBackupName + ''' WITH COPY_ONLY, NOFORMAT, NOINIT'
    PRINT (@TLSQL)

    FETCH NEXT FROM DatabaseCursor INTO @DatabaseName
END

CLOSE DatabaseCursor
DEALLOCATE DatabaseCursor
