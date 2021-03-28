--1.6.	You are allowed to teach a course only if: your job type is trainer 
--			and you have been employed for at least one year 
--			or you have attended the course yourself (as participant) 

--Betrokken tabellen: emp, term, reg en offr
--Kan worden overtreden door een insert, update in de tabel emp.
--Insert: 
-- Een nieuwe course wordt toegevoegd met een ongeldige trainer.
--Updates: 
-- Een trainer wordt ongeldig geupdate.

--We checken niet telkens of de employee wel in dienst is.
go
CREATE OR ALTER TRIGGER tr_trainerNeedsExperience
    ON offr
    AFTER INSERT, UPDATE
    AS
BEGIN
    IF @@ROWCOUNT = 0
        RETURN
    SET NOCOUNT ON
    BEGIN TRY

        IF UPDATE(trainer)
            BEGIN
                IF EXISTS(select '' from inserted where trainer is not null)
                    BEGIN
                        --Controleer of de trainer wel trainer als job heeft
                        IF EXISTS(SELECT ''
                                  FROM inserted i
                                           INNER JOIN emp e on i.trainer = e.empno
                                  WHERE e.job != 'TRAINER'
                            )
                            THROW 50000, 'De opgegeven trainer is geen trainer.', 1
                        --Controleer of de trainer lang genoeg in dienst is
                        IF EXISTS(SELECT ''
                                  FROM inserted i
                                           INNER JOIN emp e on i.trainer = e.empno
                                  WHERE e.hired > DATEADD(year, -1, GETDATE())
                            )
                            THROW 50001, 'De opgegeven trainer is niet langgenoeg in dienst.', 1
                        --Controleer of de trainer zelf de course heeft gevolgd
                        IF EXISTS(SELECT ''
                                  FROM inserted i
                                           INNER JOIN reg r on i.trainer = r.stud
                                  WHERE i.course != r.course
                            )
                            THROW 50002, 'De opgegeven trainer heeft de course niet gevogld', 1
                    END
            END
    END TRY
    BEGIN CATCH

        ; THROW
    END CATCH
END
--TESTS
GO
EXEC tSQLt.NewTestClass 'tr_trainerNeedsExperience_Test';
Go

exec tSQLt.Run 'tr_trainerNeedsExperience_Test'
create or
alter procedure tr_trainerNeedsExperience_Test.[Test false insert multiple insert error 50000]
AS
BEGIN
    --SETUP
    EXEC tSQLt.FakeTable 'COURSE.dbo.offr'
    EXEC tSQLt.ApplyTrigger 'COURSE.dbo.offr', 'tr_trainerNeedsExperience'

    --ASSERT
    exec tSQLt.ExpectException
         @ExpectedMessage = 'De opgegeven trainer is geen trainer.'

    --ACT
    INSERT INTO offr
    values ('AM4DP', GETDATE(), 'CONF', 6, 1011, 'SAN FRANCISCO'),                     --fout
           ('AM4DP', DATEADD(MONTH, -1, GETDATE()), 'CONF', 6, 1012, 'SAN FRANCISCO'), --fout
           ('AM4DP', DATEADD(MONTH, -2, GETDATE()), 'CONF', 6, 1018, 'SAN FRANCISCO') --goed
end
go
create or
alter procedure tr_trainerNeedsExperience_Test.[Test false insert multiple insert error 50001]
AS
BEGIN
    --SETUP
    EXEC tSQLt.FakeTable 'COURSE.dbo.offr'
    EXEC tSQLt.ApplyTrigger 'COURSE.dbo.offr', 'tr_trainerNeedsExperience'

    --ASSERT
    exec tSQLt.ExpectException
         @ExpectedMessage = 'De opgegeven trainer is niet langgenoeg in dienst.'

    --ACT
    UPDATE EMP set hired = DATEADD(MONTH, -1, GETDATE()), job = 'TRAINER' where empno = 1011
    UPDATE EMP set hired = DATEADD(MONTH, -2, GETDATE()), job = 'TRAINER' where empno = 1012
    UPDATE EMP set hired = DATEADD(MONTH, -14, GETDATE()), job = 'TRAINER' where empno = 1013

    INSERT INTO offr
    values ('AM4DP', GETDATE(), 'CONF', 6, 1011, 'SAN FRANCISCO'),                     --fout
           ('AM4DP', DATEADD(MONTH, -1, GETDATE()), 'CONF', 6, 1012, 'SAN FRANCISCO'), --fout
           ('AM4DP', DATEADD(MONTH, -2, GETDATE()), 'CONF', 6, 1018, 'SAN FRANCISCO') --goed
end
go
create or
alter procedure tr_trainerNeedsExperience_Test.[Test false insert multiple insert error 50002]
AS
BEGIN
    --SETUP
    EXEC tSQLt.FakeTable 'COURSE.dbo.offr'
    EXEC tSQLt.ApplyTrigger 'COURSE.dbo.offr', 'tr_trainerNeedsExperience'

    --ASSERT
    exec tSQLt.ExpectException
         @ExpectedMessage = 'De opgegeven trainer heeft de course niet gevogld'

    --ACT
    DELETE reg where stud = 1011
    UPDATE EMP set job = 'TRAINER' where empno = 1011
    DELETE reg where stud = 1012
    UPDATE EMP set job = 'TRAINER' where empno = 1012

    UPDATE EMP set job = 'TRAINER' where empno = 1013

    INSERT INTO offr
    values ('AM4DP', GETDATE(), 'CONF', 6, 1011, 'SAN FRANCISCO'),
           ('J2EE', GETDATE(), 'CONF', 6, 1012, 'SAN FRANCISCO'),
           ('RGARCH', GETDATE(), 'CONF', 6, 1013, 'SAN FRANCISCO')
end
go
create or
alter procedure tr_trainerNeedsExperience_Test.[Test true insert multiple insert]
AS
BEGIN
    --SETUP
    EXEC tSQLt.FakeTable 'COURSE.dbo.offr'
    EXEC tSQLt.ApplyTrigger 'COURSE.dbo.offr', 'tr_uniqueStartdateAndTrainer'

    --ASSERT
    exec tSQLt.ExpectNoException

    --ACT
    insert into COURSE.dbo.offr
    values ('AM4DP', GETDATE(), 'CONF', 6, 1017, 'SAN FRANCISCO'),
           ('AM4DP', DATEADD(MONTH, -2, GETDATE()), 'CONF', 6, 1018, 'SAN FRANCISCO'),
           ('AM4DP', DATEADD(MONTH, -1, GETDATE()), 'CONF', 6, 1016, 'SAN FRANCISCO')
end



