/*
#======================================================================================================================#
#                                                                                                                      #
#  Migratemaster Version 1.0, July 2020                                                                                #
#                                                                                                                      #
#  This utility was developed on a best effort basis by Azure Synapse CSE Team and Data SQL Ninja team,                #
#  to aid SQL Server to Azure Synapse Migration Practitioners.                                                         #
#  It is not an officially supported Microsoft application or tool.                                                    #
#                                                                                                                      #
#  The utility and any script outputs are provided on "AS IS" basis and                                                #
#  there are no warranties, express or implied, including, but not limited to implied warranties of merchantability    #
#  or fitness for a particular purpose.                                                                                #
#                                                                                                                      #                    
#  The utility is therefore not guaranteed to generate perfect code or output. The output needs carefully reviewed.    #
#                                                                                                                      #
#                                       USE AT YOUR OWN RISK.                                                          #
#                                                                                                                      #
#======================================================================================================================#
*/


Declare @Encoding varchar(10) = 'UTF8' 
Declare @RowDelimiter varchar(3) = '' -- '0x1E' -- 30/0x1E  is ASCII row separator
Declare @ColumnDelimiter varchar(3) = '^|^' -- '0x1F' -- 31/0x1F  ASCII Field Delimieter. Other Option: 
Declare @BatchSize int = 10000
Declare @UseCharDataType char(1) = '1' --'0' use char as storage type, '1' as nchar as storage type 
Declare @AutoCreateFileName char(1) = '0' -- '0' if you dont want timestamp as part of file name 
Declare @DestLocationPrefix varchar(80) = 'C:\migratemaster\output\2_ExportSourceData'  
Declare @FileExtention varchar(10) = '.csv'

Select '1' as Active,
db_name()  as DatabaseName, 
s.name as SchemaName, 
t.name as TableName,
@Encoding as [Encoding],
'1' as UseQuery,
'Select * from ' + s.name + '.' + t.name as Query,
@RowDelimiter as RowDelimiter,
@ColumnDelimiter as ColumnDelimiter,
@BatchSize as 'BatchSize',
@UseCharDataType as UseCharDataType,
@AutoCreateFileName as AutoCreateFileName,
@DestLocationPrefix + '\' + db_name() + '\' as DestLocation,
s.name + '_' + t.name as FileName,
@FileExtention as FileExtention
from sys.tables t 
inner join sys.schemas s 
on t.schema_id = s.schema_id 
inner join sys.databases d
on d.name = db_name()  and t.type_desc = 'USER_TABLE' 
and t.temporal_type_desc ='NON_TEMPORAL_TABLE' 
and t.object_id not in (select object_id from sys.external_tables)