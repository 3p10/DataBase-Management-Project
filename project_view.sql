-- Task 1 (Views)
-- View 1: Employee Performance Overview
CREATE OR REPLACE VIEW employee_performance_overview AS
SELECT
    e.e_id AS employee_id,
    e.emp_name AS employee_name,
    e.email AS employee_email,
    e.contract_type AS contract_type,
    e.contract_start AS contract_start_date,
    e.contract_end AS contract_end_date,
    e.salary AS salary,
    d.dep_name AS department_name,
    j.title AS job_title
FROM
    employee e
JOIN
    department d ON e.d_id = d.d_id
JOIN
    job_title j ON e.j_id = j.j_id;
 
-- View 2: Project Performance Overview
CREATE OR REPLACE VIEW project_performance_overview AS
SELECT
    p.p_id AS project_id,
    p.project_name AS project_name,
    p.p_start_date AS project_start_date,
    p.p_end_date AS project_end_date,
    c.c_name AS customer_name,
    e.emp_name AS assigned_employee
FROM
    project p
JOIN
    customer c ON p.c_id = c.c_id
LEFT JOIN
    project_role pr ON p.p_id = pr.p_id
LEFT JOIN
    employee e ON pr.e_id = e.e_id;

-- View 3: Department Employee Count
CREATE OR REPLACE VIEW department_employee_count AS
SELECT
    d.dep_name AS department_name,
    COUNT(e.e_id) AS employee_count
FROM
    department d
LEFT JOIN
    employee e ON d.d_id = e.d_id
GROUP BY
    d.dep_name;

-- View 4: Skill Distribution
CREATE OR REPLACE VIEW skill_distribution AS
SELECT
    s.skill AS skill_name,
    COUNT(es.e_id) AS employee_count
FROM
    employee_skills es
JOIN
    skills s ON es.s_id = s.s_id
GROUP BY
    s.skill;


-- Task 2 (Triggers)

-- Trigger One: Check Unique Skill
DROP TRIGGER IF EXISTS before_insert_skill ON skills;

CREATE OR REPLACE FUNCTION check_unique_skill() RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM skills WHERE skill = NEW.skill) THEN
        RAISE EXCEPTION 'Skill % already exists', NEW.skill;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_insert_skill
BEFORE INSERT ON skills
FOR EACH ROW
EXECUTE FUNCTION check_unique_skill();

-- Trigger Two: Assign Employees to New Project
CREATE OR REPLACE FUNCTION assign_employees_to_project() RETURNS TRIGGER AS $$
DECLARE
    country_code TEXT;
BEGIN
    -- Get the country of the customer associated with the new project
    SELECT country INTO country_code FROM customer WHERE c_id = NEW.c_id;

    -- Select three employees from the same country and insert project roles for them
    INSERT INTO project_role (e_id, p_id, prole_start_date)
    SELECT e.e_id, NEW.p_id, CURRENT_DATE
    FROM employee e
    JOIN geo_location l ON e.l_id = l.l_id
    WHERE l.country = country_code
    LIMIT 3;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop the trigger if it already exists
DROP TRIGGER IF EXISTS after_insert_project ON project;

-- Create the trigger after dropping the existing one
CREATE TRIGGER after_insert_project
AFTER INSERT ON project
FOR EACH ROW
EXECUTE FUNCTION assign_employees_to_project();

-- Trigger Three: Validate Employee Contract Update
CREATE OR REPLACE FUNCTION validate_contract_update() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.contract_type = 'määräaikainen' THEN
        NEW.contract_start := CURRENT_DATE;
        NEW.contract_end := NEW.contract_start + INTERVAL '2 years';
    ELSE
        NEW.contract_start := CURRENT_DATE;
        NEW.contract_end := NULL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_update_employee_contract
BEFORE UPDATE ON employee
FOR EACH ROW
WHEN (NEW.contract_type <> OLD.contract_type)
EXECUTE FUNCTION validate_contract_update();


-- Task 3 (Procedures):

-- Procedure One: Set Salary to Base Level Based on Job Title
CREATE OR REPLACE PROCEDURE set_salary_to_base_level() AS $$
BEGIN
    UPDATE employee e
    SET salary = (SELECT base_salary FROM job_title WHERE j_id = e.j_id);
END;
$$ LANGUAGE plpgsql;

-- Procedure Two: Add 3 Months to Temporary Contracts
CREATE OR REPLACE PROCEDURE extend_temporary_contracts() AS $$
BEGIN
    UPDATE employee
    SET contract_end = contract_end + INTERVAL '3 months'
    WHERE contract_type = 'määräaikainen';
END;
$$ LANGUAGE plpgsql;

-- Procedure Three: Increase Salaries by a Percentage with Optional Salary Limit
CREATE OR REPLACE PROCEDURE increase_salaries(
    IN percentage DECIMAL)
AS $$
DECLARE
    v_employee_row employee%ROWTYPE;
    v_new_salary DECIMAL;
BEGIN
    FOR v_employee_row IN SELECT * FROM employee LOOP
        v_new_salary := v_employee_row.salary * (1 + percentage / 100);
        UPDATE employee SET salary = v_new_salary WHERE e_id = v_employee_row.e_id;
    END LOOP;
END;
$$ LANGUAGE plpgsql;



-- Task 5 (Partitions)
-- Partitioning the Employee table by e_id
CREATE TABLE employee_partitioned (
    LIKE employee INCLUDING ALL
) PARTITION BY HASH (e_id);

-- Create partitions
CREATE TABLE employee_partition_1 PARTITION OF employee_partitioned FOR VALUES WITH (MODULUS 3, REMAINDER 0);
CREATE TABLE employee_partition_2 PARTITION OF employee_partitioned FOR VALUES WITH (MODULUS 3, REMAINDER 1);
CREATE TABLE employee_partition_3 PARTITION OF employee_partitioned FOR VALUES WITH (MODULUS 3, REMAINDER 2);


-- Partitioning the Customer table by c_id
CREATE TABLE customer_partitioned (
    LIKE customer INCLUDING ALL
) PARTITION BY HASH (c_id);

-- Create partitions
CREATE TABLE customer_partition_1 PARTITION OF customer_partitioned FOR VALUES WITH (MODULUS 3, REMAINDER 0);
CREATE TABLE customer_partition_2 PARTITION OF customer_partitioned FOR VALUES WITH (MODULUS 3, REMAINDER 1);
CREATE TABLE customer_partition_3 PARTITION OF customer_partitioned FOR VALUES WITH (MODULUS 3, REMAINDER 2);


CREATE TABLE project_partitions (
     p_id integer NOT NULL,
    project_name character varying COLLATE pg_catalog."default",
    budget numeric,
    commission_percentage numeric,
    p_start_date date,
    p_end_date date,
    c_id integer
) PARTITION BY RANGE (commission_percentage);

CREATE TABLE project_low PARTITION OF project_partitions FOR VALUES FROM (0) TO (10);
CREATE TABLE project_medium PARTITION OF project_partitions FOR VALUES FROM (10) TO (20);
CREATE TABLE project_high PARTITION OF project_partitions FOR VALUES FROM (20) TO (100);


-- Task 6 (Access) 

DO
$$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'admin') THEN
        CREATE ROLE admin WITH SUPERUSER;
    END IF;
END
$$;

-- Create role employee if it doesn't exist
DO
$$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'employee') THEN
        CREATE ROLE employee;
    END IF;
END
$$;


-- Task 7 (Changes)
-- Add zip_code column to Geo_location
ALTER TABLE Geo_location
ADD zip_code VARCHAR(10);

-- Add a NOT NULL constraint to customer email and project start date
ALTER TABLE Customer
ALTER COLUMN email SET NOT NULL;

-- Add start_date column to Project table
ALTER TABLE Project
ADD start_date DATE;

-- Update null start_date values in Project table
UPDATE Project
SET start_date = CURRENT_DATE
WHERE start_date IS NULL;

-- Set NOT NULL constraint on start_date column
ALTER TABLE Project
ALTER COLUMN start_date SET NOT NULL;

-- Update salary information to ensure all salaries are above 1000
UPDATE Employee
SET salary = 1200
WHERE salary < 1000;

-- Add a check constraint to employee salary to ensure it is more than 1000
ALTER TABLE Employee
ADD CONSTRAINT chk_salary CHECK (salary > 1000);


