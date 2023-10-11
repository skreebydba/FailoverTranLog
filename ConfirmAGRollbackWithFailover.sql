/* Query must be run in SQLCMD mode 
   Run the query against the primary following by the query against the secondary */
/* Connect to the primary replica */
:CONNECT fbgeveri19-vm5

USE TestDb;

/* Begin a named transaction as shown below and perform DML */
BEGIN TRANSACTION TestInsert

INSERT INTO TestTable
VALUES
('Test'
,39820)

DELETE FROM TestTable
WHERE RowId = 1;

UPDATE TestTable
SET Col1 = 'Rollback'
WHERE RowId = 1002;

/* Rollback the transaction */
ROLLBACK TRANSACTION

/* Connect to the secondary replica */
:CONNECT fbgeveri19-vm4

ALTER AVAILABILITY GROUP [fbgeveriag-ag] FAILOVER;

:CONNECT fbgeveri19-vm5
USE TestDb;

/* Get the max log sequence number for your named transaction */
DECLARE @maxlsn NVARCHAR(46);
SELECT @maxlsn = CONCAT(N'0x',MAX([Current LSN])) FROM fn_dblog(NULL,NULL) WHERE [Transaction Name] = 'TestInsert';
SELECT @maxlsn;

/* Select all transaction log records associated with the last occurrence of your named transaction as well as
   a count of the transaction operations and their associated compensation records */

SELECT [Current LSN]
,[Transaction ID]
,[Transaction Name]
,Operation
,Context
,[Description]
,[Previous LSN]
,AllocUnitName
,[Page ID]
,[Slot ID]
,[Begin Time]
,[Database Name]
,[Number of Locks]
,[Lock Information]
,[New Split Page]
FROM fn_dblog(@maxlsn,NULL);

SELECT Operation, Description, COUNT(*) AS [Operation Count]
FROM fn_dblog(@maxlsn,NULL)
WHERE Operation IN
('LOP_INSERT_ROWS'
,'LOP_DELETE_ROWS'
,'LOP_MODIFY_ROW')
AND Context = 'LCX_HEAP'
GROUP BY Operation, Description;
