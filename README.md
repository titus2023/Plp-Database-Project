
# School Database System

The School Database System is designed to manage and store critical data for a school, including student information, attendance, marks, fees, teachers, subjects, and more. The system provides a relational database schema that ensures data integrity and facilitates easy management of school-related operations.

# Key Features:
Students: 
Information such as personal details, class assignments, and parent information.

Teachers: 
Management of teacher information, including their subjects, classes, and contact details.

Exams & Marks: 
Storing exam details and students' grades.

Attendance: 
Tracking daily attendance for students.

Fees & Payments: 
Managing fees, payment status, and related transactions.

Timetable: 
Managing class timetables, subject assignments, and teacher schedules.

# School Database ERD

Relationships

A parent can have multiple students (1:M)

A student belongs to one class (M:1)

A teacher can teach multiple classes (1:M)

A class can have multiple subjects (1:M)

A subject can have multiple exams (1:M)

A student can take multiple exams, and each exam is taken by multiple students (M:N via Marks)

Attendance tracks student presence per class per date

Each fee record is tied to one student and has multiple payments (1:M)

The timetable connects classes, teachers, and subjects over specific time slots

# Link
https://drive.google.com/file/d/1aOqJ0gbAv83ZuCOsUW3WexSLsrqBxO71/view?usp=sharing
