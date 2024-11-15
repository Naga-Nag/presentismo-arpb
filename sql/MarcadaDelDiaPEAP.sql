CREATE OR ALTER FUNCTION MarcadaDelDiaPEAP(@FechaHoy DATE) 
RETURNS @Resultado TABLE 
(
  UID INT,
  MR INT,
  Nombre VARCHAR(100),
  Departamento VARCHAR(100),
  Salida DATETIME,
  Entrada DATETIME,
  Info VARBINARY(MAX)
)
AS
BEGIN
  INSERT INTO @Resultado
  SELECT
    ui.Userid AS UID,
    ui.UserCode AS MR,
    ui.Name AS Nombre,
    d.DeptName AS Departamento,
    MAX(CASE WHEN DATEPART(HOUR, ci.CheckTime) >= 13 AND (CAST(ci.CheckTime AS DATE) = @FechaHoy) THEN ci.CheckTime END) AS Salida,
    MIN(CASE WHEN DATEPART(HOUR, ci.CheckTime) <= 10 AND (CAST(ci.CheckTime AS DATE) = @FechaHoy) THEN ci.CheckTime END) AS Entrada,
    ui.OtherInfo AS Info
    
  FROM
    dbo.Userinfo ui
  INNER JOIN dbo.Dept d ON ui.Deptid = d.Deptid
  LEFT JOIN dbo.Checkinout ci ON ui.Userid = ci.Userid
  GROUP BY
    ui.Userid, ui.UserCode, ui.Name, d.DeptName, CAST(ui.OtherInfo AS VARBINARY(MAX))
  RETURN
END