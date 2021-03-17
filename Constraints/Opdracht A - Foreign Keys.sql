USE COURSE
GO

--Foreign Key van emp naar grd
ALTER TABLE emp
	ADD CONSTRAINT FK_emp_grd
	FOREIGN KEY (sgrade) REFERENCES grd(grade)
	ON UPDATE CASCADE ON DELETE NO ACTION
GO

--Foreign Key van emp naar dept
ALTER TABLE emp
	ADD CONSTRAINT FK_emp_dept
	FOREIGN KEY (deptno) REFERENCES dept(deptno)
	ON UPDATE NO ACTION	ON DELETE NO ACTION
GO

--Foreign Key van dept naar emp
ALTER TABLE dept
	ADD CONSTRAINT FK_dept_emp
	FOREIGN KEY (mgr) REFERENCES emp(empno)
	ON UPDATE NO ACTION	ON DELETE NO ACTION
GO

--Foreign Key van hist naar dept
ALTER TABLE hist
	ADD CONSTRAINT FK_hist_dept
	FOREIGN KEY (deptno) REFERENCES dept(deptno)
	ON UPDATE NO ACTION	ON DELETE NO ACTION
GO

--Foreign Key van hist naar emp
ALTER TABLE hist
	ADD CONSTRAINT FK_hist_emp
	FOREIGN KEY (empno) REFERENCES emp(empno)
	ON UPDATE NO ACTION	ON DELETE CASCADE
GO

--Foreign Key van reg naar emp
ALTER TABLE reg
	ADD CONSTRAINT FK_reg_emp
	FOREIGN KEY (stud) REFERENCES emp(empno)
	ON UPDATE NO ACTION	ON DELETE CASCADE
GO

--Foreign Key van reg naar offr
ALTER TABLE reg
	ADD CONSTRAINT FK_reg_offr
	FOREIGN KEY (course, starts) REFERENCES offr(course, starts)
	ON UPDATE NO ACTION	ON DELETE NO ACTION
GO

--Foreign Key van offr naar emp
ALTER TABLE offr
	ADD CONSTRAINT FK_offr_emp
	FOREIGN KEY (trainer) REFERENCES emp(empno)
	ON UPDATE NO ACTION	ON DELETE SET NULL
GO

--Foreign Key van offr naar crs
ALTER TABLE offr
	ADD CONSTRAINT FK_offr_crs
	FOREIGN KEY (course) REFERENCES crs(code)
	ON UPDATE CASCADE ON DELETE NO ACTION
GO

--Foreign Key van memp naar emp
ALTER TABLE memp
	ADD CONSTRAINT FK_memp_emp_empno
	FOREIGN KEY (empno) REFERENCES emp(empno)
	ON UPDATE NO ACTION ON DELETE NO ACTION
GO

--Foreign Key van memp naar emp
ALTER TABLE memp
	ADD CONSTRAINT FK_memp_emp_mgr
	FOREIGN KEY (mgr) REFERENCES emp(empno)
	ON UPDATE NO ACTION ON DELETE NO ACTION
GO

--Foreign Key van srep naar emp
ALTER TABLE srep
	ADD CONSTRAINT FK_srep_emp
	FOREIGN KEY (empno) REFERENCES emp(empno)
	ON UPDATE NO ACTION ON DELETE CASCADE
GO


--Foreign Key van term naar emp
ALTER TABLE term
	ADD CONSTRAINT FK_term_emp
	FOREIGN KEY (empno) REFERENCES emp(empno)
	ON UPDATE NO ACTION ON DELETE CASCADE
GO