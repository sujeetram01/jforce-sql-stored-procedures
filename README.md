# Employee Payroll – SQL Stored Procedures

Solution to the **JForce Solutions SQL Developer (Junior / R1) Stored Procedure Task**.
A small Employee Management and Payroll database in **MySQL 8**, with four stored procedures covering
parameters, IF / CASE logic, salary calculations, aggregation and input validation.

**Author:** Sujeet Ram

---

## Files

| File | What it contains |
| --- | --- |
| `database.sql` | Creates the `jforce_payroll` database, the `employees` table and 14 sample employees |
| `procedures.sql` | All four stored procedures |
| `test_calls.sql` | Ready-to-run `CALL` statements, including edge cases and validation errors |
| `README.md` | This explanation |

## How to run

**MySQL Workbench**
1. Open and execute `database.sql` (lightning-bolt icon).
2. Open and execute `procedures.sql`.
3. Open `test_calls.sql` and run the calls one by one (Ctrl + Enter on a line).

**MySQL command line**
```bash
mysql -u root -p < database.sql
mysql -u root -p < procedures.sql
mysql -u root -p jforce_payroll < test_calls.sql
```

Both scripts are re-runnable: the table and every procedure are dropped and re-created.

---

## Database design

```sql
employees (
    employee_id    INT            PRIMARY KEY,
    employee_name  VARCHAR(100)   NOT NULL,
    department     VARCHAR(50)    NOT NULL,
    designation    VARCHAR(50)    NOT NULL,
    basic_salary   DECIMAL(10,2)  NOT NULL  CHECK (basic_salary >= 0),
    joining_date   DATE           NOT NULL,
    status         VARCHAR(10)    NOT NULL  DEFAULT 'Active'
                                            CHECK (status IN ('Active','Inactive'))
)
```

- `DECIMAL(10,2)` for money, so there are no floating-point rounding errors.
- `CHECK` constraints stop negative salaries and invalid status values at the table level.
- An index on `department`, because every report filters by department.

**Sample data:** 14 employees in 5 departments (IT, HR, Finance, Sales, Marketing). The rows are chosen to
test every rule:

| Purpose | Employees |
| --- | --- |
| Inactive – must be excluded from reports | 105 (IT), 112 (Sales) |
| Exactly ₹60,000 – upper boundary of grade B | 104 |
| Exactly ₹30,000 – lower boundary of grade B | 107 |
| Below ₹30,000 – grade C | 103, 110, 114 |
| Above ₹60,000 – grade A | 101, 106, 108 |

---

## Stored procedures

### Task 1 – `GetEmployeeSalaryReport(department_name, minimum_salary)`

Returns **active** employees of the given department whose basic salary is **≥** the minimum, highest salary first.

```sql
CALL GetEmployeeSalaryReport('IT', 50000);
```

| Employee ID | Employee Name | Department | Designation | Basic Salary | Joining Date |
| --- | --- | --- | --- | --- | --- |
| 101 | Rahul Sharma | IT | Senior Software Engineer | 85000.00 | 2019-06-15 |
| 104 | Sneha Kulkarni | IT | Data Analyst | 60000.00 | 2022-01-17 |
| 102 | Priya Nair | IT | Software Engineer | 55000.00 | 2021-03-01 |

Vikram Singh (105, ₹52,000) is left out because he is **Inactive**.
If the department does not exist, or nobody matches, the procedure returns a message explaining why.

### Task 2 – `CalculateEmployeeSalary(employee_id)`

| Component | Rule |
| --- | --- |
| HRA | 20% of Basic |
| DA | 10% of Basic |
| PF | 12% of Basic |
| **Net Salary** | **Basic + HRA + DA − PF** |

The rates are declared once as constants (`c_hra_rate`, `c_da_rate`, `c_pf_rate`), so a rule change is a one-line edit.
Each component is rounded to 2 decimals, and Net is built from those rounded figures so the columns always add up.

```sql
CALL CalculateEmployeeSalary(101);
```

| Employee Name | Basic Salary | HRA (20%) | DA (10%) | PF (12%) | Net Salary |
| --- | --- | --- | --- | --- | --- |
| Rahul Sharma | 85000.00 | 17000.00 | 8500.00 | 10200.00 | 100300.00 |

Check: 85,000 + 17,000 + 8,500 − 10,200 = **1,00,300** ✔

### Task 3 – `EmployeeSalaryGrade(employee_id)`

Uses a `CASE` statement:

| Basic Salary | Grade |
| --- | --- |
| Below ₹30,000 | C |
| ₹30,000 – ₹60,000 (both inclusive) | B |
| Above ₹60,000 | A |

| Call | Basic Salary | Grade |
| --- | --- | --- |
| `CALL EmployeeSalaryGrade(101);` | 85000.00 | A |
| `CALL EmployeeSalaryGrade(104);` | 60000.00 | B |
| `CALL EmployeeSalaryGrade(107);` | 30000.00 | B |
| `CALL EmployeeSalaryGrade(103);` | 28000.00 | C |

### Bonus – `GetDepartmentSummary(department_name)`

Uses `COUNT`, `AVG`, `MAX`, `MIN` and `SUM`.

- **Headcount** shows total, active and inactive employees.
- **Salary figures use active employees only**, because inactive employees are not on the current payroll.

```sql
CALL GetDepartmentSummary('IT');
```

| Department | Total Employees | Active Employees | Inactive Employees | Average Salary | Highest Salary | Lowest Salary | Total Salary Expenditure |
| --- | --- | --- | --- | --- | --- | --- | --- |
| IT | 5 | 4 | 1 | 57000.00 | 85000.00 | 28000.00 | 228000.00 |

```sql
CALL GetDepartmentSummary('Legal');
-- Department "Legal" does not exist.
```

---

## Error and validation handling

Two kinds of problems are handled differently:

| Situation | Handling | Example message |
| --- | --- | --- |
| Invalid input: NULL, blank, negative | `SIGNAL SQLSTATE '45000'` – raises a real error | `Department name is required.` |
| Valid input but nothing found | Returns a one-row `Message` result | `Employee ID 999 does not exist.` |

All checks in the solution:

- Department name NULL or blank → error (Tasks 1 and Bonus)
- Minimum salary NULL or negative → error (Task 1)
- Employee ID NULL, zero or negative → error (Tasks 2 and 3)
- Department does not exist → message (Task 1 and Bonus)
- No active employee matches the filter → message (Task 1)
- Employee ID does not exist → message (Tasks 2 and 3)
- Department exists but has no active employees → message (Bonus)
- Leading/trailing spaces in a department name are trimmed, so `' IT '` works like `'IT'`

---

## Design notes

- **Naming convention:** `p_` for parameters, `v_` for local variables, `c_` for constants.
  This is deliberate: if the parameter were called `employee_id`, the condition
  `WHERE employee_id = employee_id` would compare the column with itself and match **every** row.
- **Existence is checked first** (`IF NOT EXISTS ...`), so every call returns either data or a clear reason.
- **Department matching is case-insensitive** through the table's `utf8mb4_general_ci` collation, so `'it'` also finds `'IT'`.
- **Comments** mark each section: validation, existence check, calculation and output.

## Compatibility

Written for MySQL 8.0.16+ (needed for enforced `CHECK` constraints). Uses only standard MySQL procedure
syntax (`DELIMITER`, `DECLARE`, `IF`, `CASE`, `SIGNAL`), so it also runs on MariaDB 10.6+.
