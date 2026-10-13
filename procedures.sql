-- =====================================================================
--  JForce Solutions – SQL Developer Stored Procedure Task
--  File    : procedures.sql
--  Purpose : All stored procedures for the Employee Payroll database.
--  Engine  : MySQL 8.0+ (also runs on MariaDB 10.6+)
--  Author  : Sujeet Ram
--
--  Naming convention
--    p_  = procedure parameter   (e.g. p_employee_id)
--    v_  = local variable        (e.g. v_basic_salary)
--    c_  = constant-style local  (e.g. c_hra_rate)
--  The prefixes stop a parameter from shadowing a column of the same
--  name. Without them, "WHERE employee_id = employee_id" compares the
--  column with itself and matches every row.
--
--  Error handling approach
--    * Invalid input (NULL / blank / negative)  -> SIGNAL SQLSTATE '45000'
--      so the caller gets a real error with a clear message.
--    * Valid input but nothing found            -> a friendly message
--      returned as a result set, so the demo shows why nothing came back.
-- =====================================================================

USE jforce_payroll;

DELIMITER $$

-- =====================================================================
-- Task 1 : GetEmployeeSalaryReport
--   Returns ACTIVE employees of a department whose basic salary is
--   greater than or equal to the given minimum.
--   Example: CALL GetEmployeeSalaryReport('IT', 50000);
-- =====================================================================
DROP PROCEDURE IF EXISTS GetEmployeeSalaryReport $$

CREATE PROCEDURE GetEmployeeSalaryReport(
    IN p_department_name VARCHAR(50),
    IN p_minimum_salary  DECIMAL(10,2)
)
BEGIN
    DECLARE v_department_name VARCHAR(50);
    DECLARE v_match_count     INT DEFAULT 0;

    -- Remove leading/trailing spaces so ' IT ' matches 'IT'
    SET v_department_name = LTRIM(RTRIM(p_department_name));

    -- ---- Input validation ------------------------------------------
    IF v_department_name IS NULL OR v_department_name = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Department name is required.';
    END IF;

    IF p_minimum_salary IS NULL OR p_minimum_salary < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Minimum salary must be zero or a positive amount.';
    END IF;

    -- ---- Does the department exist at all? -------------------------
    IF NOT EXISTS (SELECT 1 FROM employees WHERE department = v_department_name) THEN
        SELECT CONCAT('Department "', v_department_name, '" does not exist.') AS `Message`;
    ELSE
        -- ---- Count matching rows first so we can explain an empty result
        SELECT COUNT(*)
          INTO v_match_count
          FROM employees
         WHERE department   = v_department_name
           AND basic_salary >= p_minimum_salary
           AND status       = 'Active';

        IF v_match_count = 0 THEN
            SELECT CONCAT('No active employees in "', v_department_name,
                          '" with basic salary >= ', p_minimum_salary, '.') AS `Message`;
        ELSE
            SELECT employee_id   AS `Employee ID`,
                   employee_name AS `Employee Name`,
                   department    AS `Department`,
                   designation   AS `Designation`,
                   basic_salary  AS `Basic Salary`,
                   joining_date  AS `Joining Date`
              FROM employees
             WHERE department   = v_department_name
               AND basic_salary >= p_minimum_salary
               AND status       = 'Active'
             ORDER BY basic_salary DESC, employee_id;
        END IF;
    END IF;
END $$


-- =====================================================================
-- Task 2 : CalculateEmployeeSalary
--   Breaks an employee's basic salary into its components.
--     HRA = 20% of Basic
--     DA  = 10% of Basic
--     PF  = 12% of Basic
--     Net = Basic + HRA + DA - PF
--   Example: CALL CalculateEmployeeSalary(101);
-- =====================================================================
DROP PROCEDURE IF EXISTS CalculateEmployeeSalary $$

CREATE PROCEDURE CalculateEmployeeSalary(
    IN p_employee_id INT
)
BEGIN
    -- Salary rules kept in one place so they are easy to change
    DECLARE c_hra_rate DECIMAL(4,2) DEFAULT 0.20;
    DECLARE c_da_rate  DECIMAL(4,2) DEFAULT 0.10;
    DECLARE c_pf_rate  DECIMAL(4,2) DEFAULT 0.12;

    -- ---- Input validation ------------------------------------------
    IF p_employee_id IS NULL OR p_employee_id <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A valid positive employee ID is required.';
    END IF;

    -- ---- Check the employee exists ---------------------------------
    IF NOT EXISTS (SELECT 1 FROM employees WHERE employee_id = p_employee_id) THEN
        SELECT CONCAT('Employee ID ', p_employee_id, ' does not exist.') AS `Message`;
    ELSE
        -- ---- Calculations ------------------------------------------
        -- Inner query: each component, rounded to 2 decimals (paise).
        -- Outer query: Net = Basic + HRA + DA - PF, built from the same
        -- rounded figures so the columns always add up exactly.
        SELECT employee_name                    AS `Employee Name`,
               basic_salary                     AS `Basic Salary`,
               hra                              AS `HRA (20%)`,
               da                               AS `DA (10%)`,
               pf                               AS `PF (12%)`,
               basic_salary + hra + da - pf     AS `Net Salary`
          FROM (
                SELECT employee_name,
                       basic_salary,
                       ROUND(basic_salary * c_hra_rate, 2) AS hra,
                       ROUND(basic_salary * c_da_rate,  2) AS da,
                       ROUND(basic_salary * c_pf_rate,  2) AS pf
                  FROM employees
                 WHERE employee_id = p_employee_id
               ) AS salary_breakdown;
    END IF;
END $$


-- =====================================================================
-- Task 3 : EmployeeSalaryGrade
--   Assigns a grade from the basic salary:
--     Below 30,000          -> C
--     30,000 to 60,000      -> B   (both limits inclusive)
--     Above 60,000          -> A
--   Example: CALL EmployeeSalaryGrade(104);
-- =====================================================================
DROP PROCEDURE IF EXISTS EmployeeSalaryGrade $$

CREATE PROCEDURE EmployeeSalaryGrade(
    IN p_employee_id INT
)
BEGIN
    DECLARE v_employee_name VARCHAR(100);
    DECLARE v_basic_salary  DECIMAL(10,2);
    DECLARE v_salary_grade  CHAR(1);

    -- ---- Input validation ------------------------------------------
    IF p_employee_id IS NULL OR p_employee_id <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A valid positive employee ID is required.';
    END IF;

    -- ---- Check the employee exists before reading --------------------
    IF NOT EXISTS (SELECT 1 FROM employees WHERE employee_id = p_employee_id) THEN
        SELECT CONCAT('Employee ID ', p_employee_id, ' does not exist.') AS `Message`;
    ELSE
        SELECT employee_name, basic_salary
          INTO v_employee_name, v_basic_salary
          FROM employees
         WHERE employee_id = p_employee_id;

        -- ---- Grade rules (CASE statement) --------------------------
        CASE
            WHEN v_basic_salary < 30000  THEN SET v_salary_grade = 'C';
            WHEN v_basic_salary <= 60000 THEN SET v_salary_grade = 'B';
            ELSE                              SET v_salary_grade = 'A';
        END CASE;

        SELECT v_employee_name AS `Employee Name`,
               v_basic_salary  AS `Basic Salary`,
               v_salary_grade  AS `Salary Grade`;
    END IF;
END $$


-- =====================================================================
-- Bonus Task : GetDepartmentSummary
--   Headcount and salary statistics for one department.
--   * Headcount shows total, active and inactive employees.
--   * Salary figures use ACTIVE employees only, because inactive
--     employees are not on the current payroll.
--   * If the department does not exist, a message is returned.
--   Example: CALL GetDepartmentSummary('IT');
-- =====================================================================
DROP PROCEDURE IF EXISTS GetDepartmentSummary $$

CREATE PROCEDURE GetDepartmentSummary(
    IN p_department_name VARCHAR(50)
)
BEGIN
    DECLARE v_department_name  VARCHAR(50);
    DECLARE v_total_employees  INT DEFAULT 0;
    DECLARE v_active_employees INT DEFAULT 0;

    -- Remove leading/trailing spaces so ' IT ' matches 'IT'
    SET v_department_name = LTRIM(RTRIM(p_department_name));

    -- ---- Input validation ------------------------------------------
    IF v_department_name IS NULL OR v_department_name = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Department name is required.';
    END IF;

    -- ---- Headcount -------------------------------------------------
    -- COUNT ignores NULLs, so the CASE counts only Active rows
    SELECT COUNT(*),
           COUNT(CASE WHEN status = 'Active' THEN 1 END)
      INTO v_total_employees, v_active_employees
      FROM employees
     WHERE department = v_department_name;

    -- ---- Department not found / no active staff --------------------
    IF v_total_employees = 0 THEN
        SELECT CONCAT('Department "', v_department_name, '" does not exist.') AS `Message`;

    ELSEIF v_active_employees = 0 THEN
        SELECT CONCAT('Department "', v_department_name, '" has ', v_total_employees,
                      ' employee(s) but none are active, so there is no salary expenditure.') AS `Message`;

    ELSE
        -- ---- Summary using aggregate functions ---------------------
        SELECT v_department_name                      AS `Department`,
               v_total_employees                      AS `Total Employees`,
               v_active_employees                     AS `Active Employees`,
               v_total_employees - v_active_employees AS `Inactive Employees`,
               ROUND(AVG(basic_salary), 2)            AS `Average Salary`,
               MAX(basic_salary)                      AS `Highest Salary`,
               MIN(basic_salary)                      AS `Lowest Salary`,
               SUM(basic_salary)                      AS `Total Salary Expenditure`
          FROM employees
         WHERE department = v_department_name
           AND status     = 'Active';
    END IF;
END $$

DELIMITER ;

-- Confirm all four procedures were created
SELECT ROUTINE_NAME AS `Procedure`, CREATED AS `Created On`
  FROM information_schema.ROUTINES
 WHERE ROUTINE_SCHEMA = 'jforce_payroll'
   AND ROUTINE_TYPE   = 'PROCEDURE'
 ORDER BY ROUTINE_NAME;
