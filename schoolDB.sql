-- --------------------------------------------
-- DATABASE CREATION
-- --------------------------------------------
CREATE DATABASE IF NOT EXISTS school_db;
USE school_db;

-- --------------------------------------------
-- TABLES
-- --------------------------------------------

CREATE TABLE parents (
    parent_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    phone VARCHAR(20),
    email VARCHAR(100),
    address TEXT
);

CREATE TABLE classes (
    class_id INT AUTO_INCREMENT PRIMARY KEY,
    class_name VARCHAR(50),
    class_teacher_id INT
);

CREATE TABLE students (
    student_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    dob DATE,
    gender ENUM('Male', 'Female'),
    class_id INT,
    admission_date DATE,
    address TEXT,
    parent_id INT,
    is_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (class_id) REFERENCES classes(class_id),
    FOREIGN KEY (parent_id) REFERENCES parents(parent_id)
);

CREATE TABLE teachers (
    teacher_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20),
    subject VARCHAR(100),
    hire_date DATE
);

CREATE TABLE subjects (
    subject_id INT AUTO_INCREMENT PRIMARY KEY,
    subject_name VARCHAR(100)
);

CREATE TABLE exams (
    exam_id INT AUTO_INCREMENT PRIMARY KEY,
    exam_name VARCHAR(100),
    term VARCHAR(20),
    year YEAR
);

CREATE TABLE marks (
    mark_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT,
    subject_id INT,
    exam_id INT,
    marks_obtained DECIMAL(5,2),
    grade VARCHAR(2),
    remarks TEXT,
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (subject_id) REFERENCES subjects(subject_id),
    FOREIGN KEY (exam_id) REFERENCES exams(exam_id)
);

CREATE TABLE attendance (
    attendance_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT,
    date DATE,
    status ENUM('Present', 'Absent', 'Late'),
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);

CREATE TABLE fees (
    fee_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT,
    amount_due DECIMAL(10,2),
    amount_paid DECIMAL(10,2) DEFAULT 0,
    payment_status ENUM('Paid', 'Partially Paid', 'Unpaid'),
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);

CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT,
    amount DECIMAL(10,2),
    payment_date DATE,
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);

CREATE TABLE timetable (
    timetable_id INT AUTO_INCREMENT PRIMARY KEY,
    class_id INT,
    subject_id INT,
    teacher_id INT,
    day_of_week ENUM('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'),
    start_time TIME,
    end_time TIME,
    FOREIGN KEY (class_id) REFERENCES classes(class_id),
    FOREIGN KEY (subject_id) REFERENCES subjects(subject_id),
    FOREIGN KEY (teacher_id) REFERENCES teachers(teacher_id)
);

-- --------------------------------------------
-- STORED PROCEDURES
-- --------------------------------------------

DELIMITER $$

-- 1. Add Student
CREATE PROCEDURE add_student (
    IN fname VARCHAR(100), IN lname VARCHAR(100), IN dob DATE, IN gender ENUM('Male', 'Female'),
    IN classId INT, IN admissionDate DATE, IN address TEXT, IN parentId INT
)
BEGIN
    INSERT INTO students (first_name, last_name, dob, gender, class_id, admission_date, address, parent_id)
    VALUES (fname, lname, dob, gender, classId, admissionDate, address, parentId);
END$$

-- 2. Record Marks
CREATE PROCEDURE record_marks (
    IN studentId INT, IN subjectId INT, IN examId INT, IN marks DECIMAL(5,2), IN grade VARCHAR(2), IN remarks TEXT
)
BEGIN
    INSERT INTO marks (student_id, subject_id, exam_id, marks_obtained, grade, remarks)
    VALUES (studentId, subjectId, examId, marks, grade, remarks);
END$$

-- 3. Get Total Fees Paid
CREATE PROCEDURE get_total_fees_paid (IN studentId INT, OUT totalPaid DECIMAL(10,2))
BEGIN
    SELECT SUM(amount)
    INTO totalPaid
    FROM payments
    WHERE student_id = studentId;
END$$

-- 4. Attendance Summary
CREATE PROCEDURE get_attendance_summary (IN studentId INT)
BEGIN
    SELECT 
        student_id,
        COUNT(*) AS total_days,
        SUM(CASE WHEN status = 'Present' THEN 1 ELSE 0 END) AS days_present,
        SUM(CASE WHEN status = 'Absent' THEN 1 ELSE 0 END) AS days_absent
    FROM attendance
    WHERE student_id = studentId
    GROUP BY student_id;
END$$

-- 5. Top Students in Exam
CREATE PROCEDURE top_students_in_exam (IN examId INT)
BEGIN
    SELECT 
        s.student_id,
        CONCAT(s.first_name, ' ', s.last_name) AS student_name,
        AVG(m.marks_obtained) AS average_marks
    FROM marks m
    JOIN students s ON s.student_id = m.student_id
    WHERE m.exam_id = examId
    GROUP BY m.student_id
    ORDER BY average_marks DESC
    LIMIT 5;
END$$

-- 6. Update Student Info
CREATE PROCEDURE update_student_info (
    IN studentId INT, IN newFirstName VARCHAR(100), IN newLastName VARCHAR(100),
    IN newClassId INT, IN newAddress TEXT
)
BEGIN
    UPDATE students
    SET first_name = newFirstName,
        last_name = newLastName,
        class_id = newClassId,
        address = newAddress
    WHERE student_id = studentId;
END$$

-- 7. Update Class Teacher
CREATE PROCEDURE update_class_teacher (IN classId INT, IN newTeacherId INT)
BEGIN
    UPDATE classes
    SET class_teacher_id = newTeacherId
    WHERE class_id = classId;
END$$

-- 8. Deactivate Student
CREATE PROCEDURE deactivate_student (IN studentId INT)
BEGIN
    UPDATE students
    SET is_active = FALSE
    WHERE student_id = studentId;
END$$

-- 9. Delete Payment
CREATE PROCEDURE delete_payment (IN paymentId INT)
BEGIN
    DELETE FROM payments WHERE payment_id = paymentId;
END$$

-- 10. Report Card
CREATE PROCEDURE student_report_card (IN studentId INT, IN examId INT)
BEGIN
    SELECT 
        s.first_name, s.last_name, c.class_name,
        sub.subject_name, m.marks_obtained, m.grade, m.remarks
    FROM marks m
    JOIN students s ON m.student_id = s.student_id
    JOIN subjects sub ON m.subject_id = sub.subject_id
    JOIN classes c ON s.class_id = c.class_id
    WHERE m.student_id = studentId AND m.exam_id = examId;
END$$

-- 11. Outstanding Fees Report
CREATE PROCEDURE students_with_pending_fees ()
BEGIN
    SELECT 
        s.student_id,
        CONCAT(s.first_name, ' ', s.last_name) AS student_name,
        f.amount_due,
        f.amount_paid,
        (f.amount_due - f.amount_paid) AS balance
    FROM fees f
    JOIN students s ON f.student_id = s.student_id
    WHERE f.payment_status != 'Paid';
END$$

-- 12. Teacher Timetable View
CREATE PROCEDURE teacher_timetable (IN teacherId INT)
BEGIN
    SELECT 
        t.day_of_week,
        t.start_time,
        t.end_time,
        c.class_name,
        s.subject_name
    FROM timetable t
    JOIN classes c ON t.class_id = c.class_id
    JOIN subjects s ON t.subject_id = s.subject_id
    WHERE t.teacher_id = teacherId
    ORDER BY FIELD(t.day_of_week, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'), t.start_time;
END$$

-- --------------------------------------------
-- TRIGGER
-- --------------------------------------------
CREATE TRIGGER after_payment_insert
AFTER INSERT ON payments
FOR EACH ROW
BEGIN
    DECLARE totalPaid DECIMAL(10,2);
    DECLARE dueAmount DECIMAL(10,2);

    SELECT SUM(amount) INTO totalPaid
    FROM payments
    WHERE student_id = NEW.student_id;

    SELECT amount_due INTO dueAmount
    FROM fees
    WHERE student_id = NEW.student_id;

    IF totalPaid >= dueAmount THEN
        UPDATE fees
        SET amount_paid = totalPaid,
            payment_status = 'Paid'
        WHERE student_id = NEW.student_id;
    ELSE
        UPDATE fees
        SET amount_paid = totalPaid,
            payment_status = 'Partially Paid'
        WHERE student_id = NEW.student_id;
    END IF;
END$$

DELIMITER ;



-- -------------------------------
-- 1. PARENTS
-- -------------------------------
INSERT INTO parents (name, phone, email, address) VALUES
('John Mwangi', '0712345678', 'johnmwangi@gmail.com', 'Nairobi'),
('Grace Wambui', '0723456789', 'gracewambui@gmail.com', 'Mombasa'),
('Peter Otieno', '0734567890', 'peterotieno@gmail.com', 'Kisumu'),
('Lucy Njeri', '0745678901', 'lucynjeri@gmail.com', 'Nakuru'),
('James Kiptoo', '0756789012', 'jameskiptoo@gmail.com', 'Eldoret');

-- -------------------------------
-- 2. TEACHERS
-- -------------------------------
INSERT INTO teachers (first_name, last_name, email, phone, subject, hire_date) VALUES
('Alice', 'Kamau', 'alice.kamau@gmail.com', '0700000001', 'Mathematics', '2020-01-15'),
('Brian', 'Odhiambo', 'brian.odhiambo@gmail.com', '0700000002', 'English', '2019-02-20'),
('Catherine', 'Cherono', 'catherine.cherono@gmail.com', '0700000003', 'Biology', '2021-03-10'),
('David', 'Omondi', 'david.omondi@gmail.com', '0700000004', 'Chemistry', '2022-04-12'),
('Eva', 'Mutua', 'eva.mutua@gmail.com', '0700000005', 'Geography', '2018-05-18');

-- -------------------------------
-- 3. CLASSES
-- -------------------------------
INSERT INTO classes (class_name, class_teacher_id) VALUES
('Form 1 Blue', 1),
('Form 2 Green', 2),
('Form 3 Red', 3),
('Form 4 Yellow', 4),
('Form 1 White', 5);

-- -------------------------------
-- 4. SUBJECTS
-- -------------------------------
INSERT INTO subjects (subject_name) VALUES
('Mathematics'),
('English'),
('Biology'),
('Chemistry'),
('Geography');

-- -------------------------------
-- 5. STUDENTS
-- -------------------------------
INSERT INTO students (first_name, last_name, dob, gender, class_id, admission_date, address, parent_id) VALUES
('Mary', 'Atieno', '2007-03-15', 'Female', 1, '2022-01-10', 'Kisumu', 1),
('John', 'Kariuki', '2006-06-22', 'Male', 2, '2021-01-10', 'Nyeri', 2),
('Jane', 'Oduor', '2005-09-10', 'Female', 3, '2020-01-10', 'Kakamega', 3),
('Tom', 'Njoroge', '2004-12-01', 'Male', 4, '2019-01-10', 'Nairobi', 4),
('Lilian', 'Chebet', '2007-01-25', 'Female', 5, '2023-01-10', 'Eldoret', 5);

-- -------------------------------
-- 6. EXAMS
-- -------------------------------
INSERT INTO exams (exam_name, term, year) VALUES
('Mid Term 1', 'Term 1', 2025),
('End Term 1', 'Term 1', 2025),
('Mid Term 2', 'Term 2', 2025),
('End Term 2', 'Term 2', 2025),
('End Year', 'Term 3', 2025);

-- -------------------------------
-- 7. MARKS
-- -------------------------------
INSERT INTO marks (student_id, subject_id, exam_id, marks_obtained, grade, remarks) VALUES
(1, 1, 1, 78.5, 'B+', 'Good job'),
(2, 2, 2, 65.0, 'B', 'Fair'),
(3, 3, 3, 92.0, 'A', 'Excellent'),
(4, 4, 4, 54.5, 'C', 'Needs improvement'),
(5, 5, 5, 88.0, 'A-', 'Very good');

-- -------------------------------
-- 8. ATTENDANCE
-- -------------------------------
INSERT INTO attendance (student_id, date, status) VALUES
(1, '2025-05-01', 'Present'),
(2, '2025-05-01', 'Absent'),
(3, '2025-05-01', 'Present'),
(4, '2025-05-01', 'Late'),
(5, '2025-05-01', 'Present');

-- -------------------------------
-- 9. FEES
-- -------------------------------
INSERT INTO fees (student_id, amount_due, amount_paid, payment_status) VALUES
(1, 20000.00, 15000.00, 'Partially Paid'),
(2, 20000.00, 20000.00, 'Paid'),
(3, 20000.00, 0.00, 'Unpaid'),
(4, 20000.00, 5000.00, 'Partially Paid'),
(5, 20000.00, 20000.00, 'Paid');

-- -------------------------------
-- 10. PAYMENTS
-- -------------------------------
INSERT INTO payments (student_id, amount, payment_date) VALUES
(1, 15000.00, '2025-03-10'),
(2, 20000.00, '2025-03-11'),
(4, 5000.00, '2025-03-15'),
(5, 10000.00, '2025-03-18'),
(5, 10000.00, '2025-03-25');

-- -------------------------------
-- 11. TIMETABLE
-- -------------------------------
INSERT INTO timetable (class_id, subject_id, teacher_id, day_of_week, start_time, end_time) VALUES
(1, 1, 1, 'Monday', '08:00:00', '09:30:00'),
(2, 2, 2, 'Tuesday', '09:30:00', '11:00:00'),
(3, 3, 3, 'Wednesday', '08:00:00', '09:30:00'),
(4, 4, 4, 'Thursday', '09:30:00', '11:00:00'),
(5, 5, 5, 'Friday', '08:00:00', '09:30:00');
