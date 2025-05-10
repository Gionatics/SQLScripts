DECLARE @Count int = 1
DECLARE @result varchar(max)
DECLARE @DBCounts int = (SELECT COUNT(name) FROM master.sys.databases WHERE name NOT IN ('','') AND state_desc = 'ONLINE') -- filter databases here
DECLARE @DBName varchar(MAX)
DECLARE @sizeToShrink varchar(20) = '1' -- set the minimum size of data or log file shrink, mostly default is 1.

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
    dbname nvarchar(MAX),
    command nvarchar(MAX)
)

INSERT INTO #temp
SELECT ROW_NUMBER() OVER(ORDER BY name ASC) AS Row,name
FROM master.sys.databases
WHERE name NOT IN ('','') AND state_desc = 'ONLINE'

WHILE @Count <= @DBCounts
BEGIN
    SET @DBName = (SELECT name FROM #temp WHERE row = @Count)

    INSERT INTO #tempresultholder
    (
        dbname,
        command
    )

    SELECT dbname = @DBNname,
    command = 'USE ' + @DBName + '; DBCC SHRINKFILE (N''' + mf.name + ''', ' + @sizeToShrink + ');'
    FROM sys.master_files mf
    JOIN sys.databases d
    ON mf.database_id = d.database_id
    WHERE DB_NAME(database_id) = @DBName

    SET @Count = @Count + 1
END

SELECT * FROM #tempresultholder WHERE command LIKE ('%log%') -- change the filter if you want look for data, log, or both file, usually shrinking is for log files.
