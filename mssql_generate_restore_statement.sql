/***** This script is being used to generate restore statements for multiple databases mentioned in filter *****/

/** 
Generate restore TSQL statements via using open-souce tool "restoregene" 
credits for: PabloBrewster on doing an amazing tool to make work easier. Github Link: https://github.com/PabloBrewster/RestoreGene/blob/main/sp_RestoreGene.sql

To make the script below work, instance needs to have the said tool created as stored procedure in "master" DB.
**/

DECLARE @Count int = 1
DECLARE @result varchar(max)
DECLARE @DBCounts int = (SELECT COUNT(name) FROM master.sys.databases WHERE name NOT IN ('') AND state_desc = 'ONLINE') -- filter database, used for loop counter
DECLARE @DBName varchar(MAX)
DECLARE @datapath nvarchar(200)
DECLARE @logpath nvarchar(200)

--SET DATAPATH
SELECT TOP 1
@datapath = LEFT(saf.filename,(LEN(saf.filename)-LEN(REVERSE(LEFT(REVERSE(saf.filename),CHARINDEX('\',REVERSE(saf.filename))-1)))))
FROM master.dbo.sysaltfiles saf, master.dbo.sysdatabases sdb
WHERE LEFT(saf.filename, (LEN(saf.filename) - LEN(REVERSE(LEFT(REVERSE(saf.filename),CHARINDEX('\',REVERSE(saf.filename))-1))))) NOT LIKE '%System%' AND
LEFT(saf.filename, (LEN(saf.filename) - LEN(REVERSE(LEFT(REVERSE(saf.filename), CHARINDEX('\',REVERSE(saf.filename))-1))))) NOT LIKE '%tempdb%' AND
saf.dbid = sdb.dbid
ORDER BY saf.filename ASC

--SET LOGPATH
SELECT TOP 1
@logpath = LEFT(saf.filename,(LEN(saf.filename)-LEN(REVERSE(LEFT(REVERSE(saf.filename),CHARINDEX('\',REVERSE(saf.filename))-1)))))
FROM master.dbo.sysaltfiles saf, master.dbo.sysdatabases sdb
WHERE LEFT(saf.filename, (LEN(saf.filename) - LEN(REVERSE(LEFT(REVERSE(saf.filename),CHARINDEX('\',REVERSE(saf.filename))-1))))) NOT LIKE '%System%' AND
LEFT(saf.filename, (LEN(saf.filename) - LEN(REVERSE(LEFT(REVERSE(saf.filename), CHARINDEX('\',REVERSE(saf.filename))-1))))) NOT LIKE '%tempdb%' AND
saf.dbid = sdb.dbid
ORDER BY saf.filename ASC

IF (OBJECT_ID('tempdb..#temp') is not null)
BEGIN
    DROP TABLE #temp
END

IF (OBJECT_ID('tempdb..#tempresultholder') is not null)
BEGIN
    DROP TABLE #tempresultholder
END

CREATE TABLE #temp
(
    row int,
    name nvarchar(200)
)

CREATE TABLE #tempresultholder
(
    TSQL nvarchar(MAX),
    Backupdate nvarchar(MAX),
    Backupdevice nvarchar(MAX),
    last_lsn nvarchar(MAX),
    database_name nvarchar(MAX),
    sort_sequence int
)

INSERT INTO #temp
SELECT ROW_NUMBER() OVER(ORDER BY name ASC) AS Row,name
FROM master.sys.databases
WHERE name NOT IN ('') AND state_desc = 'ONLINE' -- filter database, used for loop counter

WHILE @Count <= @DBCounts
BEGIN
    SET @DBName = (SELECT name FROM #temp WHERE row = @Count)

    SET @Result = (
    SELECT 'exec
    dbo.sp_RestoreGene @database=''' + @DBName + ''',
    @withrecovery=0,
    @withreplace=1,
    @withmovedatafiles = ''' + @dataPath + ''',
    @withmovelogfile = ''' + @logPath + '''') + ';'
    + CHAR(13) + CHAR(10) + ' GO'

    /*
    INSERT INTO #tempresultholder
    (
        TSQL,
        Backupdate,
        Backupdevice,
        last_lsn,
        database_name,
        sort_sequence
    )
    EXEC
    dbo.sp_RestoreGene @database=@DBName,
    @withrecovery=0,
    @withreplace=1,
    @withmovedatafiles =  @dataPath,
    @withmovelogfile = @logPath;
    */

    SET @Count = @Count + 1

    PRINT @Result
END
/*************************************************************************************************************************************************/
