USE BD;
ALTER TABLE dbo.Userinfo ADD Activo BIT;
ALTER TABLE dbo.Userinfo ADD Jornada TINYINT;
ALTER TABLE dbo.Userinfo ADD CUIL NVARCHAR(50);