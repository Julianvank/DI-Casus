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
CREATE OR ALTER TRIGGER presidentOrManagerNeedsAdmin
ON emp
AFTER UPDATE
AS
BEGIN
	IF @@ROWCOUNT = 0
		RETURN
	SET NOCOUNT ON
	BEGIN TRY
		SELECT * FROM inserted
		select * from deleted

		SELECT * 
		FROM inserted i
		WHERE EXISTS (
				SELECT '' 
				FROM emp e 
				JOIN deleted d 
				ON d.empno = e.empno
				WHERE e.empno = i.empno
				AND d.job = 'ADMIN')

		SELECT * 
		FROM inserted i
		WHERE EXISTS (
				SELECT '' 
				FROM emp e 
				JOIN deleted d 
				ON d.empno = e.empno
				WHERE e.empno = i.empno
				AND d.job = 'ADMIN')
		AND NOT EXISTS (SELECT '' 
						FROM emp e
						WHERE e.empno = i.empno 
						AND job = 'ADMIN' 
						AND deptno = (
							SELECT deptno FROM emp 
							WHERE empno = i.empno
						)
						AND e.empno <> i.empno)
		AND EXISTS (SELECT '' 
						FROM emp e
						WHERE (job = 'PRESIDENT' OR job = 'MANAGER')
						AND deptno = (
							SELECT deptno FROM emp 
							WHERE empno = i.empno))

		SELECT * 
		FROM inserted i
		WHERE EXISTS (SELECT '' 
						FROM emp e
						WHERE (job = 'PRESIDENT' OR job = 'MANAGER')
						AND deptno = (
							SELECT deptno FROM emp 
							WHERE empno = i.empno)
						)

		IF UPDATE(job)
			--Als de employee die geupdate moet worden een admin is, hij de laatste admin uit het department is en er is een president of manager aanwezig, dan geef error.
			IF EXISTS (SELECT '' 
						FROM inserted i
						WHERE EXISTS (
								SELECT '' 
								FROM emp e 
								WHERE e.empno = i.empno
								AND (SELECT job FROM deleted) = 'ADMIN')
						AND NOT EXISTS (SELECT '' 
										FROM emp e 
										WHERE e.empno = i.empno 
										AND job = 'ADMIN' 
										AND deptno = (
											SELECT deptno FROM emp 
											WHERE empno = i.empno
										)
										AND e.empno <> i.empno) 
						AND EXISTS (SELECT '' 
									FROM emp e
									WHERE (job = 'PRESIDENT' OR job = 'MANAGER')
									AND deptno = (
										SELECT deptno FROM emp 
										WHERE empno = i.empno)
									)
			)
			THROW 50002, 'Het is niet mogelijk om de job van de laatste admin in een department aan te passen als er een president of manager in dit department aanwezig is.', 1
	END TRY
	BEGIN CATCH
		THROW
	END CATCH
END

ROLLBACK TRAN

SELECT * FROM emp

--Test voor een invalide situatie. Een salesrep wordt naar een president veranderd, terwijl er geen admin aanwezig is in het department.
--Verwacht: error
BEGIN TRAN
--Trigger
insert into dept(deptno,dname,loc,mgr) values(16,'MARKETING2','ARNHEM',1003);
INSERT INTO emp
VALUES(2000, 'Bart', 'SALESREP', '1975-01-01', '2020-02-02', 4, 4800, 'BART', 16)

UPDATE emp
SET job = 'PRESIDENT'
WHERE empno = 2000

--Stored Procedure (geeft de andere error, waardoor testen van deze situatie eigenlijk overbodig is en nooit voor zal moeten komen)
EXEC usp_upd_employeeJob @empno = 1004, @job = 'PRESIDENT'
ROLLBACK TRAN

--Test voor een valide situatie. Een salesrep wordt naar een president veranderd, terwijl er wel een admin aanwezig is in het department.
--Verwacht: Employee 1011 krijg als job president.
BEGIN TRAN
--Trigger
UPDATE emp
SET job = 'PRESIDENT'
WHERE empno = 1011

--Stored Procedure
EXEC usp_upd_employeeJob @empno = 1011, @job = 'PRESIDENT'
ROLLBACK TRAN

--Test voor een invalide situatie. De job van de laatste admin in een department wordt naar salesrep veranderd.
--Verwacht: error
BEGIN TRAN
--Trigger
UPDATE emp
SET job = 'SALESREP'
WHERE empno BETWEEN 1001 AND 1002

--Stored Procedure
EXEC usp_upd_employeeJob @empno = 1002, @job = 'SALESREP'
ROLLBACK TRAN

--Test voor een valide situatie. De job van een admin in een department met meerdere admins wordt naar salesrep veranderd.
--Verwacht: Employee 1019 krijgt als job salesrep.
BEGIN TRAN
EXEC usp_upd_employeeJob @empno = 1019, @job = 'SALESREP'
ROLLBACK TRAN


CREATE OR ALTER PROCEDURE usp_upd_employeeJob
@empno numeric(4),
@job varchar(9)
AS
BEGIN
	--IS NOT GEEN MULTI STATEMENT TRIGGER
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


--2. The company hires adult personnel only.
--Betrokken tabellen: emp
--Kan worden overtreden door een insert en update in de tabel emp.
--Insert: Nieuwe employee waarbij de waarde van born + 18 jaar kleiner is dan de huidige datum.
--Update: De waarde van born + 18 jaar van een bestaande employee wordt kleiner dan de huidige datum.
ALTER TABLE emp
	ADD CONSTRAINT CK_emp_adult
	CHECK (DATEADD(YEAR, 18, born) < hired)
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