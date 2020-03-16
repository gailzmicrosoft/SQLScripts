
/***************************************************************************************/
/*           T-SQL Script to test important and relevant database information          */ 
/*                          Gaiye "Gail" Zhou, Architect                               */
/*                               May 2017                                              */
/***************************************************************************************/
-- (1)
-- Use below SP to get DB size in particular DB
-- Use AdventureWorks2017
-- Exec sp_spaceused


--(2) Use below Scripts to get all DB Sizes 
SELECT      sdb.name,  
            CONVERT(VARCHAR,SUM(smf.size)*8.0/1024.0) AS [SizeMB],
			CONVERT(VARCHAR,SUM(smf.size)*8.0/1024/1024.0) AS [SizeGB], 
			CONVERT(VARCHAR,SUM(smf.size)*8.0/1024/1024.0/1024.0) AS [SizeTB]  
FROM        sys.databases sdb  
JOIN        sys.master_files smf
ON          sdb.database_id=smf.database_id
where  sdb.name not in ('master','tempdb','msdb','model') and sdb.state = 0 
GROUP BY    sdb.name  
ORDER BY    sdb.name 