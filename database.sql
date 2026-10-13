-- =====================================================================
--  JForce Solutions – SQL Developer Stored Procedure Task
--  File    : database.sql
--  Purpose : Create the payroll database, the employees table and
--            load sample data.
--  Engine  : MySQL 8.0+ (also runs on MariaDB 10.6+)
--  Author  : Sujeet Ram
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Database
-- ---------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS jforce_payroll
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_general_ci;

USE jforce_payroll;

-- Re-runnable: drop the table if it already exists
DROP TABLE IF EXISTS employees;

-- ---------------------------------------------------------------------
-- 2. Employees table
--    - NOT NULL on every business column (no incomplete records)
--    - CHECK constraints keep salary non-negative and status valid
--    - Index on department because every report filters by it
-- ---------------------------------------------------------------------
CREATE TABLE employees (
    employee_id    INT            NOT NULL,
    employee_name  VARCHAR(100)   NOT NULL,
    department     VARCHAR(50)    NOT NULL,
    designation    VARCHAR(50)    NOT NULL,
    basic_salary   DECIMAL(10,2)  NOT NULL,
    joining_date   DATE           NOT NULL,
    status         VARCHAR(10)    NOT NULL DEFAULT 'Active',

    CONSTRAINT pk_employees        PRIMARY KEY (employee_id),
    CONSTRAINT chk_basic_salary    CHECK (basic_salary >= 0),
    CONSTRAINT chk_employee_status CHECK (status IN ('Active', 'Inactive'))
);

CREATE INDEX idx_employees_department ON employees (department);

-- ---------------------------------------------------------------------
-- 3. Sample data – 14 employees, 5 departments
--    Chosen on purpose to exercise every rule in the procedures:
--      * Inactive employees (105, 112) – must be excluded from reports
--      * Salary exactly 30,000 (107) and 60,000 (104) – grade boundaries
--      * Salaries below 30,000 (103, 110, 114) – grade C
--      * Salaries above 60,000 (101, 106, 108) – grade A
-- ---------------------------------------------------------------------
INSERT INTO employees
    (employee_id, employee_name, department, designation, basic_salary, joining_date, status)
VALUES
    (101, 'Rahul Sharma',    'IT',        'Senior Software Engineer', 85000.00, '2019-06-15', 'Active'),
    (102, 'Priya Nair',      'IT',        'Software Engineer',        55000.00, '2021-03-01', 'Active'),
    (103, 'Amit Patil',      'IT',        'Junior Developer',         28000.00, '2024-07-10', 'Active'),
    (104, 'Sneha Kulkarni',  'IT',        'Data Analyst',             60000.00, '2022-01-17', 'Active'),
    (105, 'Vikram Singh',    'IT',        'System Administrator',     52000.00, '2018-11-05', 'Inactive'),
    (106, 'Neha Joshi',      'HR',        'HR Manager',               72000.00, '2017-04-20', 'Active'),
    (107, 'Karan Mehta',     'HR',        'HR Executive',             30000.00, '2023-08-01', 'Active'),
    (108, 'Pooja Deshmukh',  'Finance',   'Finance Manager',          95000.00, '2016-09-12', 'Active'),
    (109, 'Rohan Gupta',     'Finance',   'Accountant',               42000.00, '2020-02-25', 'Active'),
    (110, 'Anjali Verma',    'Finance',   'Accounts Assistant',       25000.00, '2025-01-06', 'Active'),
    (111, 'Suresh Iyer',     'Sales',     'Sales Executive',          35000.00, '2022-05-30', 'Active'),
    (112, 'Meera Reddy',     'Sales',     'Sales Manager',            68000.00, '2019-10-14', 'Inactive'),
    (113, 'Arjun Rao',       'Marketing', 'Marketing Analyst',        48000.00, '2021-12-01', 'Active'),
    (114, 'Kavya Shetty',    'Marketing', 'Content Writer',           29500.00, '2024-02-19', 'Active');

-- ---------------------------------------------------------------------
-- 4. Quick check
-- ---------------------------------------------------------------------
SELECT * FROM employees ORDER BY employee_id;
