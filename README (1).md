# Smart Parking Slot Booking System

A database-driven mini project developed using **MySQL and MySQL Workbench** for the Database Management System (DBMS) subject at Chandigarh University.

## Project Overview

The Smart Parking Slot Booking System manages users, vehicles, parking slots, bookings, and payments through a relational database. It helps check parking slot availability for a selected time interval, prevents conflicting bookings through basic trigger-based validation, and calculates parking fees automatically.

## Features

- User management and vehicle registration
- Parking slot management with hourly rates
- Time-based parking slot availability checking
- Booking management and cancellation
- Automatic parking fee calculation
- Prevention of overlapping confirmed bookings
- Booking details using SQL views and JOINs
- Payment tracking and revenue reports
- Database constraints and transaction examples

## Technologies Used

- **Database:** MySQL
- **Database Tool:** MySQL Workbench
- **Language:** SQL

## Database Tables

| Table | Purpose |
|---|---|
| `users` | Stores user information |
| `vehicles` | Stores registered vehicles |
| `parking_slots` | Stores parking slot details and hourly rates |
| `bookings` | Stores reservations and booking fees |
| `payments` | Stores payment amounts and statuses |

## Installation and Execution

1. Install MySQL Server and MySQL Workbench.
2. Download `Smart_Parking_DBMS_Complete_Code.sql` from the repository.
3. Open MySQL Workbench and connect to your MySQL server.
4. Open the SQL file.
5. Execute the script.
6. Review the created tables and query results.

**Important:** The script drops and recreates the project's tables. Run it in a fresh or dedicated demo database, and back up any important data first.

## Sample SQL Queries

Display all parking slots:

```sql
SELECT * FROM parking_slots;
```

Display booking details:

```sql
SELECT * FROM v_booking_details;
```

Calculate total revenue from paid payments:

```sql
SELECT SUM(amount) AS total_paid_revenue
FROM payments
WHERE pay_status = 'Paid';
```

## Project Limitations

This is an SQL-based academic mini project. It does not include a customer-facing website, mobile application, real payment gateway, or live parking sensors. Trigger-based booking validation also requires additional transaction and locking safeguards for production use.

## Future Enhancements

- Web or mobile application
- Online payment gateway integration
- QR-code-based booking verification
- IoT sensors for real-time slot occupancy
- Email or SMS booking notifications
- Administrative dashboard

## Academic Details

- **University:** Chandigarh University
- **Institute:** University Institute of Computing
- **Subject:** Database Management System
- **Subject Code:** 25CAT-203
- **Student:** Kushager
- **UID:** 25BCD10039
- **Semester:** 3rd
- **Submitted To:** Ms. Sonali Dadwal, Assistant Professor

## Repository Contents

- `Smart_Parking_DBMS_Complete_Code.sql` — complete database implementation
- `README.md` — project documentation
- `Smart_Parking_DBMS_Case_Study.pdf` — project report, if included
- `screenshots/` — actual MySQL Workbench outputs, if included

---

*This project demonstrates practical applications of relational database design, SQL queries, constraints, joins, views, triggers, and transactions.*
