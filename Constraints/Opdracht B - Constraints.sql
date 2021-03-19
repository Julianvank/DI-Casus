USE COURSE
GO
--1. A department that employs the president or a manager should also employ at least one administrator.
--Betrokken tabellen: emp, term
--Kan worden overtreden door een insert, update en delete in de tabel emp.

--Insert: Nieuwe president of manager zonder dat er een admin bestaat in hetzelfde department. (emp tabel)
--Updates: 
--	- De job van de enige admin in een department wordt geupdate als er een president of manager in hetzelfde department aanwezig is. (emp tabel)
--	- De job van een employee in een department wordt geupdate naar een president of manager als er geen admin in hetzelfde department aanwezig is. (emp tabel)
--	- De department van een president of manager wordt geupdate naar een department zonder admin. (emp tabel)
--	- De department van de enige admin in een department wordt geupdate als er een president of manager in de oude department aanwezig was. (emp tabel)
--	- De enige admin in een department wordt terminated als er een president of manager in de department aanwezig is. (emp & term tabel)
--Delete: De enige admin in een department wordt gedelete als er een president of manager in de department aanwezig is. (emp tabel)

--Gekozen voor een trigger op de tabel emp. Er wordt gecheckt op een update van job of deptno. 
--Als de job van een bestaande employee wordt veranderd naar president of manager, moet er ook een admin aanwezig zijn.
--Als het department van een bestaande president of manager wordt veranderd, moet er in het nieuwe department een admin bestaan.
CREATE OR ALTER TRIGGER deptWithPresidentOrManagerNeedsAdmin
ON emp
AFTER UPDATE, INSERT
AS
BEGIN
	IF @@ROWCOUNT = 0
		RETURN
	SET NOCOUNT ON
	BEGIN TRY
		IF UPDATE(job) OR UPDATE(deptno)
		BEGIN
			IF EXISTS (SELECT '' 
						FROM inserted i 
						WHERE i.job IN ('PRESIDENT', 'MANAGER')
			)
			AND EXISTS (SELECT '' 
						FROM inserted i 
						INNER JOIN emp e ON e.deptno = i.deptno
						WHERE (SELECT COUNT(job) 
								FROM emp 
								WHERE deptno = i.deptno 
								AND job = 'ADMIN') = 0
			)
				THROW 50001, 'Op deze department bestaat nog geen admin. Elke department met een president of manager moet ook een admin hebben.', 1
		END
	END TRY
	BEGIN CATCH
		;THROW
	END CATCH
END

SELECT * FROM emp

--Test voor een invalide situatie. Een salesrep wordt naar een president veranderd, terwijl er geen admin aanwezig is in het department.
--Verwacht: error
BEGIN TRAN
INSERT INTO dept 
VALUES (16, 'MARKETING2', 'ARNHEM', 1003);
INSERT INTO emp
VALUES (2000, 'Bart', 'SALESREP', '1975-01-01', '2020-02-02', 4, 4800, 'BART', 16)

UPDATE emp
SET job = 'PRESIDENT'
WHERE empno = 2000
ROLLBACK TRAN

--Test voor een valide situatie. Een salesrep wordt naar een president veranderd, terwijl er wel een admin aanwezig is in het department.
--Verwacht: Employee 1011 krijgt als job president.
BEGIN TRAN
UPDATE emp
SET job = 'PRESIDENT'
WHERE empno = 1011
ROLLBACK TRAN

--Test voor een invalide situatie. Het department van een president wordt veranderd naar een department zonder admin.
--Verwacht: error
BEGIN TRAN
INSERT INTO dept 
VALUES (16, 'MARKETING2', 'ARNHEM', 1003);
INSERT INTO emp
VALUES (2000, 'Bart', 'SALESREP', '1975-01-01', '2020-02-02', 4, 4800, 'BART', 16)

UPDATE emp
SET deptno = 16
WHERE empno = 1000
ROLLBACK TRAN

--Test voor een valide situatie. Het department van een president wordt veranderd naar een department met admin.
--Verwacht: Employee 1000 krijgt als department 15
BEGIN TRAN
UPDATE emp
SET deptno = 15
WHERE empno = 1000
ROLLBACK TRAN

/* Stored Procedure voor constraint 1
CREATE OR ALTER PROCEDURE usp_upd_employeeJob
@empno numeric(4),
@job varchar(9)
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
		--Als job president of manager is, check of er geen admins aanwezig zijn in dat department.
		IF(@job = 'PRESIDENT' OR @job = 'MANAGER') AND NOT EXISTS (
			SELECT empno FROM emp 
			WHERE job = 'ADMIN' 
			AND deptno = (
				SELECT deptno FROM emp 
				WHERE empno = @empno
			)
			AND empno <> @empno
			--EXCEPT
			--SELECT empno FROM term
		)
		THROW 50001, 'Er is geen admin aanwezig in het department.', 1

		--Als de employee die geupdate moet worden een admin is, hij de laatste admin uit het department is en er is een president of manager aanwezig, geef dan een error.
		IF EXISTS (SELECT empno FROM emp 
					WHERE empno = @empno 
					AND job = 'ADMIN'
		) AND NOT EXISTS (SELECT empno FROM emp 
						WHERE job = 'ADMIN' 
						AND deptno = (
							SELECT deptno FROM emp 
							WHERE empno = @empno
						)
						AND empno <> @empno
						EXCEPT
						SELECT empno FROM term
		) AND EXISTS (SELECT empno FROM emp 
						WHERE (job = 'PRESIDENT' OR job = 'MANAGER')
						AND deptno = (
							SELECT deptno FROM emp 
							WHERE empno = @empno
						)
						EXCEPT
						SELECT empno FROM term 
		)
		THROW 50002, 'Het is niet mogelijk om de job van de laatste admin in een department aan te passen als er een president of manager in dit department aanwezig is.', 1

		UPDATE emp
		SET job = @job
		WHERE empno = @empno
	END TRY
	BEGIN CATCH
		THROW
	END CATCH
END
*/


--2. The company hires adult personnel only.
--Betrokken tabellen: emp
--Kan worden overtreden door een insert en update in de tabel emp.
--Insert: Nieuwe employee waarbij de waarde van born + 18 jaar kleiner is dan de huidige datum.
--Update: De waarde van born + 18 jaar van een bestaande employee wordt kleiner dan de huidige datum.
ALTER TABLE emp
	ADD CONSTRAINT CK_emp_adult
	CHECK (DATEADD(YEAR, 18, born) <= hired)
GO

SELECT * FROM emp

--Test voor een invalide situatie. Nieuwe employee die jonger is dan 18. (insert)
--Verwacht: error
BEGIN TRAN
INSERT INTO emp
VALUES(2000, 'Bart', 'ADMIN', '2020-01-01', '2020-02-02', 4, 4800, 'BART', 15)
ROLLBACK TRAN

--Test voor een invalide situatie. Geboortedatum van employee wordt jonger dan 18. (update)
--Verwacht: error
BEGIN TRAN
UPDATE emp
SET born = '2020-01-01'
WHERE empno = 1000
ROLLBACK TRAN

--Test voor een valide situatie. Nieuwe employee die ouder is dan 18. (insert)
--Verwacht: Nieuwe record in de emp tabel
BEGIN TRAN
INSERT INTO emp
VALUES(2000, 'Bart', 'ADMIN', '1975-01-01', '2020-02-02', 4, 4800, 'BART', 15)
ROLLBACK TRAN

--Test voor een valide situatie. Geboortedatum van employee blijft ouder dan 18. (update)
--Verwacht: Waarde van born wordt aangepast naar nieuwe geboortedatum.
BEGIN TRAN
UPDATE emp
SET born = '1975-01-01'
WHERE empno = 1000
ROLLBACK TRAN

--3. The llimit of a salary grade must be higher than the llimit of the next lower salary grade. 
--The ulimit of the salary grade must be higher than the ulimit of the next lower salary grade. 
--Note; the numbering of grades can contain holes.
--Betrokken tabel: grd
--Kan overtreden worden door een insert of update in de tabel grd.

--Inserts:
--	- De llimit is lager dan de llimit van een lagere grd.
--	- De ulimit is lager dan de ulimit van een lagere grd.
--Updates: 
--	- De llimit wordt lager dan de llimit van een lagere grd.
--	- De ulimit wordt lager dan de ulimit van een lagere grd.

--Gekozen voor een trigger op de tabel grd. Er wordt gecheckt op een update van llimit of ulimit.
--De llimit van een bestaande salarisschaal mag niet kleiner worden dan llimit van een schaal lager.
--De ulimit van een bestaande salarisschaal mag niet kleiner worden dan ulimit van een schaal lager.
CREATE OR ALTER TRIGGER salaryGradesCannotOverlap
ON grd
AFTER UPDATE, INSERT
AS
BEGIN
	IF @@ROWCOUNT = 0
		RETURN
	SET NOCOUNT ON
	BEGIN TRY
		IF UPDATE(llimit) OR UPDATE(ulimit)
		BEGIN
			IF EXISTS (SELECT '' 
						FROM inserted i 
						WHERE EXISTS (
									SELECT ''		
									FROM grd g 
									WHERE g.grade < i.grade 
									AND (
										i.llimit < g.llimit OR 
										i.ulimit < g.ulimit
									)
						)
			)
				THROW 50002, 'Salarisschalen mogen niet overlappen.', 1
		END
	END TRY
	BEGIN CATCH
		;THROW
	END CATCH
END

SELECT * FROM grd

--Test voor een invalide situatie. De llimit van een grade wordt lager dan de llimit van de lagere grade.
--Verwacht: error
BEGIN TRAN
UPDATE grd
SET llimit = 800.0
WHERE grade = 3
ROLLBACK TRAN

--Test voor een valide situatie. De llimit van een grade wordt niet lager dan de llimit van de lagere grade.
--Verwacht: error
BEGIN TRAN
UPDATE grd
SET llimit = 1000.01
WHERE grade = 3
ROLLBACK TRAN

--Test voor een invalide situatie. De ulimit van een grade wordt lager dan de ulimit van de lagere grade.
--Verwacht: error
BEGIN TRAN
UPDATE grd
SET ulimit = 2000.0
WHERE grade = 3
ROLLBACK TRAN

--Test voor een valide situatie. De ulimit van een grade wordt niet lager dan de ulimit van de lagere grade.
--Verwacht: error
BEGIN TRAN
UPDATE grd
SET ulimit = 2500.01
WHERE grade = 3
ROLLBACK TRAN