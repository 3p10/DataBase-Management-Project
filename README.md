# Overview of DB-Management-Project
This project focuses on modifications and enhancements to a database schema to improve **data organization, access control, and performance**. Key developments include the creation of **views**, **triggers**, **procedures**, **partitions**, and the implementation of **access rights** and **schema changes**. The work demonstrates advanced database management techniques and solutions for real-world scenarios.
# Features
### Views
Custom views were created to provide summarized and insightful data for improved management and analysis:
* Employee Performance Overview: A comprehensive view combining employee details with department and job title information.
* Project Performance Overview: A project-centric view integrating customer details and assigned employees.
* Department Employee Count: Displays the number of employees in each department.
* Skill Distribution: Illustrates the distribution of skills across employees.
### Triggers
Implemented advanced triggers to automate database tasks:
* Ensure Unique Skills: Validates the uniqueness of skills during insertion.
* Auto-Assign Employees to Projects: Automatically assigns employees to new projects based on customer location.
* Validate Employee Contracts: Ensures contract details are consistent with contract types.
### Procedures
Developed reusable procedures to enhance database management:
* Set Salaries by Job Title: Updates employee salaries to the base level for their roles.
* Extend Temporary Contracts: Extends temporary contracts by three months.
* Increase Salaries with Limits: Adjusts salaries by a percentage with an optional limit.
### Partitions
Implemented partitioning to optimize performance and manageability:
* Hash Partitioning: Applied to employee and customer tables for balanced distribution.
* Range Partitioning: Used in the project table for commission-based segmentation.
### Access Rights
Defined roles to enforce database security:
* Admin: Full superuser privileges.
* Employee: Restricted access based on responsibilities.
### Schema Changes
Enhanced the schema for better data integrity:
* Added zip_code to the Geo_location table.
* Set NOT NULL constraints on critical fields.
* Enforced salary minimums and added constraints for consistency.
# Technologies
This project was developed using:
* PostgreSQL for database management.
* PL/pgSQL for writing triggers and procedures.

