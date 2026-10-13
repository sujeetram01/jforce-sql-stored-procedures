-- =====================================================================
--  JForce Solutions – SQL Developer Stored Procedure Task
--  File    : test_calls.sql
--  Purpose : Execute every procedure with normal and edge-case inputs.
--            Run after database.sql and procedures.sql.
-- =====================================================================

USE jforce_payroll;

-- ---------------------------------------------------------------------
-- Task 1 : GetEmployeeSalaryReport
-- ---------------------------------------------------------------------
CALL GetEmployeeSalaryReport('IT', 50000);        -- 101, 104, 102 (105 is Inactive, so excluded)
CALL GetEmployeeSalaryReport('Finance', 40000);   -- 108, 109
CALL GetEmployeeSalaryReport('HR', 100000);       -- message: no active employees match
CALL GetEmployeeSalaryReport('Legal', 10000);     -- message: department does not exist

-- ---------------------------------------------------------------------
-- Task 2 : CalculateEmployeeSalary
-- ---------------------------------------------------------------------
CALL CalculateEmployeeSalary(101);   -- Basic 85,000 -> Net 100,300
CALL CalculateEmployeeSalary(110);   -- Basic 25,000 -> Net  29,500
CALL CalculateEmployeeSalary(999);   -- message: employee does not exist

-- ---------------------------------------------------------------------
-- Task 3 : EmployeeSalaryGrade  (one employee per rule + both boundaries)
-- ---------------------------------------------------------------------
CALL EmployeeSalaryGrade(101);   -- 85,000 -> A
CALL EmployeeSalaryGrade(104);   -- 60,000 -> B (upper boundary)
CALL EmployeeSalaryGrade(107);   -- 30,000 -> B (lower boundary)
CALL EmployeeSalaryGrade(103);   -- 28,000 -> C
CALL EmployeeSalaryGrade(999);   -- message: employee does not exist

-- ---------------------------------------------------------------------
-- Bonus : GetDepartmentSummary
-- ---------------------------------------------------------------------
CALL GetDepartmentSummary('IT');        -- 5 employees, 4 active
CALL GetDepartmentSummary('Finance');
CALL GetDepartmentSummary('Legal');     -- message: department does not exist

-- ---------------------------------------------------------------------
-- Validation errors (each raises SQLSTATE 45000 with a clear message).
-- Run these one at a time – an error stops the rest of a script.
-- ---------------------------------------------------------------------
-- CALL GetEmployeeSalaryReport('', 50000);     -- Department name is required.
-- CALL GetEmployeeSalaryReport('IT', -1);      -- Minimum salary must be zero or a positive amount.
-- CALL CalculateEmployeeSalary(NULL);          -- A valid positive employee ID is required.
-- CALL EmployeeSalaryGrade(-5);                -- A valid positive employee ID is required.
-- CALL GetDepartmentSummary(NULL);             -- Department name is required.
