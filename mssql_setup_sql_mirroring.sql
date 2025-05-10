/** Monitoring DB Mirroring health **/
SELECT
    @@SERVERNAME AS 'Instance',
    db.name,
    db.state_desc,
    dm.mirroring_role_desc,
    dm.mirroring_state_desc,
    dm.mirroring_safety_level_desc,
    dm.mirroring_partner_name,
    dm.mirroring_partner_instance
FROM sys.databases db
INNER JOIN sys.database_mirroring dm
ON db.database_id = dm.database_id
WHERE dm.mirroring_role_desc is not null
ORDER BY db.name

--Create endpoint
CREATE ENDPOINT [Mirroring]
    STATE = STARTED
    AS TCP (LISTENER_PORT = 5022, LISTENER_IP = ALL)
    FOR DATA_MIRRORING (ROLE = PARTNER, AUTHENTICATION = WINDOWS NEGOTIATE
    , ENCRYPTION = REQUIRED ALGORITHM AES)
GO
/**************************************/

/** Steps below are being used to setup mirroring in databases. Run each step **/
/** Create login and grant access to principal and mirror **/
DECLARE @SvcAccount AS nvarchar(20)

SELECT DISTINCT @SvcAccount = service_account FROM sys.dm_server_services WHERE servicename LIKE 'SQL Server%'

SELECT 'CREATE LOGIN [' + @SvcAccount + ']' + ' FROM WINDOWS WITH DEFAULT_DATABASE=[master]'
+ CHAR(13) + CHAR(10) + ' PRINT ''[' + @SvcAccount + '] granted access. '';'
/**************************************/

/** Generate TSQL to add DBs in mirroring **/
DECLARE @Servername AS nvarchar(50) = ''
DECLARE @port AS nvarchar(4) = ''
DECLARE @partner AS nvarchar(50) = 'TCP://' + @Servername + ':' + @port + ''

SELECT 'ALTER DATABASE [' + DB_NAME(database_id) + '] SET PARTNER = ''' + @partner + '''' + ';' 
+ CHAR(13) + CHAR(10) + ' PRINT ''[' + DB_NAME(database_id) + '] mirroring added.'';' AS 'TSQL'
FROM master.sys.database_mirroring
WHERE DB_NAME(database_id) NOT IN ('')
/**************************************/
  
/** Other useful scripts for DB Mirroring **/
/** TSQL to remove DBs in mirroring **/
SELECT 'ALTER DATABASE [' + DB_NAME(database_id) + '] SET PARTNER OFF;' AS 'TSQL'
FROM master.sys.database_mirroring
WHERE mirroring_state_desc = 'SYNCHRONIZED'
/**************************************/

/** TSQL to failover mirroring DBs **/
SELECT 'ALTER DATABASE [' + DB_NAME(database_id) + '] SET PARTNER FAILOVER;' AS 'TSQL'
FROM master.sys.database_mirroring
WHERE mirroring_guid IS NOT NULL AND mirroring_state_desc = 'SYNCHRONIZED'
/**************************************/
  
/** TSQL to resume/suspend DB mirroring **/
SELECT 'ALTER DATABASE [' + DB_NAME(database_id) + '] SET PARTNER RESUME;' AS 'TSQL'
FROM master.sys.database_mirroring
WHERE mirroring_state_desc = 'SYNCHRONIZED'
/**************************************/

/** TSQL to set multiple DBs to High Performance (Async) **/
DECLARE @Count int = 1
DECLARE @result varchar(max)
DECLARE @DBCounts int = (SELECT COUNT(*) FROM master.sys.database_mirroring
WHERE DB_NAME(database_id) NOT IN ('','') AND mirroring_state_desc = 'SYNCHRONIZED') -- filter database
DECLARE @DBName varchar(MAX)

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
SELECT ROW_NUMBER() OVER(ORDER BY DB_NAME(database_id) ASC) AS Row,DB_Name(database_id) AS 'name'
FROM master.sys.database_mirroring
WHERE DB_NAME(database_id) NOT IN ('','') AND mirroring_state_desc = 'SYNCHRONIZED'

WHILE @Count <= @DBCounts
BEGIN
    SET @DBName = (SELECT name FROM #temp WHERE row = @Count)

    INSERT INTO #tempresultholder
    (
        dbname,
        command
    )

    SELECT dbname = @DBNname,
    command = 'USE ' + @DBName + '; ALTER DATABASE [' + @DBName + '] SET SAFETY OFF;' + ' PRINT ''[' + @DBName + '] set to High Performance / Asynchronous.'';'
    FROM master.sys.database_mirroring
    WHERE DB_NAME(database_id) = @DBName AND mirroring_state_desc = 'SYNCHRONIZED'

    SET @Count = @Count + 1
END

SELECT * FROM #tempresultholder
/**************************************/
