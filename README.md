# CAPSDBClassTools

This project creates classes and Stored procedures based off of SQL Server schemas in order to speed up the creation of database and mid-tier development using CRUD Stored Procedures.

The following types of files can be created:

	Partial Object classes for each table found in a database.

	CRUD stored procedures for each table.
	
	Partial Object Classes with CRUD methods are also created.

	API Controller classes for each Object class. With proper routing for GET, POST, PUT, and DELETE

	A WCF web service IService and Service.cs file is also created that includes unique methods for each CRUD operation for each table.

