-- Smart Parking Slot Booking System
-- DBMS Case Study | MySQL 8.0+
-- Run in a fresh academic/demo environment.
-- This is a database-layer project; no real payment gateway or physical sensors are connected.

CREATE DATABASE IF NOT EXISTS smart_parking;
USE smart_parking;

-- Drop objects in dependency order so this script can be rerun.
DROP VIEW IF EXISTS v_booking_details;
DROP TRIGGER IF EXISTS trg_bookings_before_insert_fee;
DROP TRIGGER IF EXISTS trg_bookings_before_update_fee;
DROP TRIGGER IF EXISTS trg_bookings_before_insert_overlap;
DROP TRIGGER IF EXISTS trg_bookings_before_update_overlap;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS bookings;
DROP TABLE IF EXISTS parking_slots;
DROP TABLE IF EXISTS vehicles;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    phone VARCHAR(20) NOT NULL,
    user_type ENUM('Customer', 'Admin') NOT NULL DEFAULT 'Customer'
);

CREATE TABLE vehicles (
    vehicle_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    plate_no VARCHAR(20) NOT NULL UNIQUE,
    vehicle_type ENUM('Car', 'Bike', 'SUV', 'EV') NOT NULL,
    CONSTRAINT fk_vehicles_users
        FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE parking_slots (
    slot_id INT AUTO_INCREMENT PRIMARY KEY,
    slot_code VARCHAR(10) NOT NULL UNIQUE,
    slot_type ENUM('Car', 'Bike', 'SUV', 'EV') NOT NULL,
    hourly_rate DECIMAL(8,2) NOT NULL,
    slot_status ENUM('Active', 'Maintenance') NOT NULL DEFAULT 'Active',
    CONSTRAINT chk_hourly_rate_positive CHECK (hourly_rate > 0)
);

CREATE TABLE bookings (
    booking_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    vehicle_id INT NOT NULL,
    slot_id INT NOT NULL,
    start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    status ENUM('Confirmed', 'Cancelled', 'Completed') NOT NULL DEFAULT 'Confirmed',
    est_fee DECIMAL(10,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_bookings_users
        FOREIGN KEY (user_id) REFERENCES users(user_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_bookings_vehicles
        FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_bookings_slots
        FOREIGN KEY (slot_id) REFERENCES parking_slots(slot_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_booking_time CHECK (end_time > start_time),
    CONSTRAINT chk_est_fee_nonnegative CHECK (est_fee >= 0),
    INDEX idx_booking_slot_time_status (slot_id, status, start_time, end_time)
);

CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT NOT NULL UNIQUE,
    amount DECIMAL(10,2) NOT NULL,
    payment_method ENUM('Cash', 'Card', 'UPI', 'Online') NOT NULL DEFAULT 'UPI',
    pay_status ENUM('Pending', 'Paid', 'Failed', 'Refunded') NOT NULL DEFAULT 'Pending',
    pay_time DATETIME NULL,
    CONSTRAINT fk_payments_bookings
        FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_payment_amount CHECK (amount >= 0)
);

DELIMITER $$

-- Fee rule: every started hour is charged as a full hour.
CREATE TRIGGER trg_bookings_before_insert_fee
BEFORE INSERT ON bookings
FOR EACH ROW
BEGIN
    DECLARE v_rate DECIMAL(8,2);
    IF NEW.end_time <= NEW.start_time THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Booking end time must be later than start time';
    END IF;

    SELECT hourly_rate INTO v_rate
    FROM parking_slots
    WHERE slot_id = NEW.slot_id;

    SET NEW.est_fee =
        v_rate * CEIL(TIMESTAMPDIFF(MINUTE, NEW.start_time, NEW.end_time) / 60.0);
END$$

CREATE TRIGGER trg_bookings_before_update_fee
BEFORE UPDATE ON bookings
FOR EACH ROW
BEGIN
    DECLARE v_rate DECIMAL(8,2);
    IF NEW.end_time <= NEW.start_time THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Booking end time must be later than start time';
    END IF;

    SELECT hourly_rate INTO v_rate
    FROM parking_slots
    WHERE slot_id = NEW.slot_id;

    SET NEW.est_fee =
        v_rate * CEIL(TIMESTAMPDIFF(MINUTE, NEW.start_time, NEW.end_time) / 60.0);
END$$

-- Reject overlapping confirmed reservations for the same slot.
-- Overlap condition: existing start < requested end AND existing end > requested start.
CREATE TRIGGER trg_bookings_before_insert_overlap
BEFORE INSERT ON bookings
FOR EACH ROW
BEGIN
    IF NEW.status = 'Confirmed' AND EXISTS (
        SELECT 1
        FROM bookings b
        WHERE b.slot_id = NEW.slot_id
          AND b.status = 'Confirmed'
          AND b.start_time < NEW.end_time
          AND b.end_time > NEW.start_time
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Parking slot is already booked for an overlapping time';
    END IF;
END$$

CREATE TRIGGER trg_bookings_before_update_overlap
BEFORE UPDATE ON bookings
FOR EACH ROW
BEGIN
    IF NEW.status = 'Confirmed' AND EXISTS (
        SELECT 1
        FROM bookings b
        WHERE b.slot_id = NEW.slot_id
          AND b.booking_id <> OLD.booking_id
          AND b.status = 'Confirmed'
          AND b.start_time < NEW.end_time
          AND b.end_time > NEW.start_time
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Parking slot is already booked for an overlapping time';
    END IF;
END$$

DELIMITER ;

-- Sample users
INSERT INTO users (name, email, phone, user_type) VALUES
('Aarav Sharma', 'aarav@example.com', '9876500001', 'Customer'),
('Diya Verma', 'diya@example.com', '9876500002', 'Customer'),
('Kabir Singh', 'kabir@example.com', '9876500003', 'Customer'),
('Ananya Gupta', 'ananya@example.com', '9876500004', 'Customer'),
('Ishaan Mehta', 'ishaan@example.com', '9876500005', 'Customer'),
('Admin User', 'admin@example.com', '9876500006', 'Admin');

-- Sample vehicles
INSERT INTO vehicles (user_id, plate_no, vehicle_type) VALUES
(1, 'CH01AB1234', 'Car'),
(2, 'CH01CD5678', 'Bike'),
(3, 'PB10EF9012', 'SUV'),
(4, 'CH01GH3456', 'EV'),
(5, 'HR26JK7890', 'Car'),
(6, 'CH01LM2468', 'EV');

-- Sample parking slots
INSERT INTO parking_slots (slot_code, slot_type, hourly_rate, slot_status) VALUES
('A01', 'Car', 40.00, 'Active'),
('A02', 'Car', 40.00, 'Active'),
('B01', 'Bike', 20.00, 'Active'),
('C01', 'EV', 60.00, 'Active'),
('D01', 'SUV', 50.00, 'Active'),
('M01', 'Car', 35.00, 'Maintenance');

-- Sample bookings; no same-slot time intervals overlap.
INSERT INTO bookings (user_id, vehicle_id, slot_id, start_time, end_time, status) VALUES
(1, 1, 1, '2026-11-01 10:00:00', '2026-11-01 12:00:00', 'Confirmed'),
(2, 2, 3, '2026-11-01 09:00:00', '2026-11-01 11:00:00', 'Confirmed'),
(3, 3, 5, '2026-11-01 10:00:00', '2026-11-01 13:00:00', 'Confirmed'),
(4, 4, 4, '2026-11-01 14:00:00', '2026-11-01 16:00:00', 'Confirmed'),
(5, 5, 2, '2026-11-01 12:00:00', '2026-11-01 14:00:00', 'Confirmed'),
(6, 6, 1, '2026-11-01 13:00:00', '2026-11-01 15:00:00', 'Confirmed');

-- Sample payments
INSERT INTO payments (booking_id, amount, payment_method, pay_status, pay_time) VALUES
(1, 80.00, 'UPI', 'Paid', '2026-11-01 09:55:00'),
(2, 40.00, 'Cash', 'Paid', '2026-11-01 08:55:00'),
(3, 150.00, 'Card', 'Paid', '2026-11-01 09:50:00'),
(4, 120.00, 'UPI', 'Pending', NULL),
(5, 80.00, 'Online', 'Paid', '2026-11-01 11:55:00'),
(6, 80.00, 'UPI', 'Paid', '2026-11-01 12:55:00');

-- Booking details view
CREATE VIEW v_booking_details AS
SELECT
    b.booking_id,
    u.name AS user_name,
    u.email,
    v.plate_no,
    v.vehicle_type,
    s.slot_code,
    s.slot_type,
    s.hourly_rate,
    b.start_time,
    b.end_time,
    b.status AS booking_status,
    b.est_fee
FROM bookings b
JOIN users u ON b.user_id = u.user_id
JOIN vehicles v ON b.vehicle_id = v.vehicle_id
JOIN parking_slots s ON b.slot_id = s.slot_id;

-- Example 1: Display users
SELECT * FROM users;

-- Example 2: Vehicles and their owners
SELECT v.vehicle_id, u.name, v.plate_no, v.vehicle_type
FROM vehicles v
JOIN users u ON v.user_id = u.user_id
ORDER BY u.name;

-- Example 3: Check available active slots for 10:00-12:00 on 1 Nov 2026
SELECT s.slot_id, s.slot_code, s.slot_type, s.hourly_rate
FROM parking_slots s
WHERE s.slot_status = 'Active'
  AND NOT EXISTS (
      SELECT 1
      FROM bookings b
      WHERE b.slot_id = s.slot_id
        AND b.status = 'Confirmed'
        AND b.start_time < '2026-11-01 12:00:00'
        AND b.end_time > '2026-11-01 10:00:00'
  )
ORDER BY s.slot_code;

-- Example 4: Show booking details
SELECT * FROM v_booking_details ORDER BY booking_id;

-- Example 5: Total revenue from paid payments.
-- Expected from the sample data: ₹430.00
SELECT COALESCE(SUM(amount), 0) AS total_paid_revenue
FROM payments
WHERE pay_status = 'Paid';

-- Example 6: Payment totals by status
SELECT pay_status, COUNT(*) AS payment_count, SUM(amount) AS total_amount
FROM payments
GROUP BY pay_status
ORDER BY pay_status;

-- Example 7: Users with more than one booking
SELECT u.user_id, u.name, COUNT(b.booking_id) AS booking_count
FROM users u
JOIN bookings b ON b.user_id = u.user_id
GROUP BY u.user_id, u.name
HAVING COUNT(b.booking_id) > 1;

-- Example 8: Booking history for one user
SELECT *
FROM v_booking_details
WHERE email = 'aarav@example.com'
ORDER BY start_time DESC;

-- Example 9: Cancel a booking (uncomment to execute)
-- UPDATE bookings SET status = 'Cancelled' WHERE booking_id = 1;

-- Example 10: Mark a payment as paid (uncomment to execute)
-- UPDATE payments
-- SET pay_status = 'Paid', pay_time = NOW()
-- WHERE booking_id = 4;

-- Transaction demonstration: the change is undone by ROLLBACK.
START TRANSACTION;
UPDATE bookings SET status = 'Cancelled' WHERE booking_id = 2;
ROLLBACK;

-- Concurrency note:
-- Trigger-based overlap validation is useful for a basic project but can have race
-- conditions under simultaneous booking requests. A production system should serialize
-- booking attempts per slot (for example, lock the parking_slots row with SELECT ... FOR UPDATE
-- inside a transaction, then check overlap and insert) and test concurrent requests.
