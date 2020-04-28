--*****************************************************************************************
-- Scripts to set up parquet file export from and import into Azure Synapse DW
-- Gaiye "Gail" Zhou, April 2020 
--*****************************************************************************************

-- (0) Assign Managed Identity for Azure Synapse SQL Server 
-- Set up Managed Identity for Azure Synapse 
--Use virtual network service endpoints and rules for database servers
--https://docs.microsoft.com/en-us/azure/sql-database/sql-database-vnet-service-endpoint-rule-overview?toc=/azure/sql-data-warehouse/toc.json
Connect-AzAccount
Select-AzSubscription -SubscriptionId <subscriptionId>
Set-AzSqlServer -ResourceGroupName your-database-server-resourceGroup -ServerName your-SQL-servername -AssignIdentity

-- Example 
Connect-AzAccount
Select-AzSubscription -SubscriptionId ab123cd1-e123-1234-5678-12fd34c5cc67
Set-AzSqlServer -ResourceGroupName resourceGroupName -ServerName SqlSverNameShort -AssignIdentity


-- List exsisting objects (so you dont overwrite them by accident) 

Select * from sys.database_credentials
Select * from sys.external_data_sources 
Select * from sys.external_file_formats



-- (1) Create Parquet File Format 
--drop external file format ParquetFile
CREATE EXTERNAL FILE FORMAT [ParquetFile]
WITH (
FORMAT_TYPE = PARQUET)

CREATE EXTERNAL FILE FORMAT ParquetFileSnappy  
WITH (  
FORMAT_TYPE = PARQUET,  
DATA_COMPRESSION = 'org.apache.hadoop.io.compress.SnappyCodec')

CREATE EXTERNAL FILE FORMAT ParquetFileGzip  
WITH (  
FORMAT_TYPE = PARQUET,  
DATA_COMPRESSION =  'org.apache.hadoop.io.compress.GzipCodec')


--(2) Create Database Scoped Cridential 

--drop DATABASE SCOPED CREDENTIAL msi_cred 
CREATE DATABASE SCOPED CREDENTIAL msi_cred WITH IDENTITY = 'Managed Service Identity';


--(3) Create External Data Source 

CREATE EXTERNAL DATA SOURCE adls_ds
WITH (
TYPE = hadoop, 
LOCATION = 'abfss://containername@adlsaccountname.dfs.core.windows.net', 
CREDENTIAL = msi_cred);
 


--(4) Export table into Blob Storage useing CETAS 
--create schema ext

--drop External Table ext.DimAccountAdls  
drop External Table ext.DimAccountAdlsDfs 
Create External Table ext.DimAccountAdlsDfs 
With 
(
	LOCATION='/export/dbo_DimAccountAdlsDfs', -- exported is the folder name under container name, dbo_Account is the subfolder under export 
	DATA_SOURCE = adls_ds,
	FILE_FORMAT = ParquetFile
)
As Select * from [dbo].[DimAccount] 

-- test results 
select * from ext.DimAccountAdlsDfs 


--(5) Import the parquet file into Azure Synapse Table
CREATE TABLE [dbo].[DimAccount_for_parquet]
(
	[AccountKey] [int] NOT NULL,
	[ParentAccountKey] [int] NULL,
	[AccountCodeAlternateKey] [int] NULL,
	[ParentAccountCodeAlternateKey] [int] NULL,
	[AccountDescription] [nvarchar](50) NULL,
	[AccountType] [nvarchar](50) NULL,
	[Operator] [nvarchar](50) NULL,
	[CustomMembers] [nvarchar](300) NULL,
	[ValueType] [nvarchar](50) NULL,
	[CustomMemberOptions] [nvarchar](200) NULL
)
WITH
(
	DISTRIBUTION = HASH ( [AccountKey] ),
	CLUSTERED COLUMNSTORE INDEX
)
GO

-- From blob Storage 
Truncate Table [dbo].[DimAccount_for_parquet]
Insert into [dbo].[DimAccount_for_parquet]
Select * from ext.DimAccountAdlsDfs 




--*****************************************************************************************
-- COPY INTO 
-- Need to set up Managed Identity 
--*****************************************************************************************

-- How to set up managed identity for your Azure Synapse SQL Server 
-- and then allow it to access your storage 
--https://techcommunity.microsoft.com/t5/azure-synapse-analytics/msg-10519-when-attempting-to-access-external-table-via-polybase/ba-p/690641


Truncate Table [dbo].[DimAccount_for_parquet]
COPY INTO [dbo].[DimAccount_for_parquet]
FROM 'https://adlsaccountname.dfs.core.windows.net/containername/export/dbo_DimAccountAdlsDfs' -- this will take in all files in the folder 
--FROM 'https://adlsaccountname.dfs.core.windows.net/containername/export/dbo_DimAccountAdlsDfs/*.parq'
WITH
(
  FILE_TYPE = 'PARQUET',
  -- CREDENTIAL=(IDENTITY= 'Shared Access Signature', SECRET='')
  CREDENTIAL = (IDENTITY= 'Managed Identity')
) 

Select * from ext.DimAccountAdlsDfs 

