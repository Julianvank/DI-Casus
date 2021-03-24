USE COURSE
GO
--4. The start date and known trainer uniquely identify course offerings. 
	--Note: the constraint ‘ofr_unq’ is too strict, this does not allow multiple unknown trainers on the same start date, 
	--this unique constraint should therefore be dropped. 
	--Create a new constraint to implement the constraint, the use of a filtered index is not allowed.

--Betrokken tabellen: offr
--Kan worden overtreden door een insert en update

--Insert:
--Updates: 

--Drop constraint
ALTER TABLE offr
DROP CONSTRAINT ofr_unq

--Get date
select * from offr

--Make constraint
CREATE OR ALTER TRIGGER tr_uniqueStartdateAndTrainer
ON offr
AFTER INSERT
AS
begin
    	IF @@ROWCOUNT = 0
		RETURN
	    SET NOCOUNT ON

    begin try
                    if exists(select 1
                              from (
                                       select count(trainer) as ntrainers
                                       from offr
                                       where trainer is not null
                                       group by starts, trainer
                                   ) as o
                              where ntrainers <> 1
                        )
                        THROW 50000, 'De trainer en tijd moeten uniek zijn', 1

    end try

    begin catch
        ;THROW
    end catch
end

--TESTS
    --foute test
Begin TRAN
    insert into offr
    values ('RGDEV', '2019-07-02', 'CONF', 6, 1015, 'SAN FRANCISCO'),
           ('RGDEV', '2019-05-02', 'CONF', 6, null, 'SAN FRANCISCO'),
           ('RGDEV', '2019-06-02', 'CONF', 6, null, 'SAN FRANCISCO'),
           ('RGARCH', '2019-07-02', 'CONF', 6, 1015, 'SAN FRANCISCO')
rollback tran
    --GOEDE TESTS
begin tran
    insert into offr
    values ('RGDEV', '2019-07-02', 'CONF', 6, 1018, 'SAN FRANCISCO'),
           ('PLSQL', '2019-07-02', 'CONF', 6, null, 'SAN FRANCISCO'),
           ('J2EE', '2019-07-02', 'CONF', 6, null, 'SAN FRANCISCO'),
           ('RGARCH', '2019-07-02', 'CONF', 6, 1015, 'SAN FRANCISCO')
rollback tran

