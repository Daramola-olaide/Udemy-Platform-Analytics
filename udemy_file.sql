CREATE DATABASE udemy;

#Create all tables and import dataset
CREATE TABLE udemy_course (
course_id INT PRIMARY KEY,
course_title VARCHAR(200),
is_paid VARCHAR(10),
price INT,
num_subscribers INT,
num_reviews INT,
num_lectures INT,
level VARCHAR(25),
content_duration FLOAT,
published_timestamp VARCHAR(100),
subject VARCHAR(100)
);

CREATE TABLE reviews(
course_id INT PRIMARY KEY,
num_subscribers INT,
num_reviews INT,
num_lectures INT,
content_duration FLOAT,
published_timestamp VARCHAR(200),
subject VARCHAR(100),
FOREIGN KEY (course_id) REFERENCES udemy_course(course_id)
);

CREATE TABLE tutors
(
course_id INT PRIMARY KEY,
num_lectures INT,
subject VARCHAR(100),
tutor_id INT,
FOREIGN KEY (course_id) REFERENCES udemy_course(course_id)
);

CREATE TABLE payments(
course_id INT PRIMARY KEY,
is_paid VARCHAR(10),
price INT,
num_subscribers INT,
subject VARCHAR(100),
FOREIGN KEY (course_id) REFERENCES udemy_course(course_id)
);

CREATE TABLE courses(
course_id INT PRIMARY KEY,
course_title VARCHAR(200),
subject VARCHAR(100),
FOREIGN KEY (course_id) REFERENCES udemy_course(course_id)
);

USE udemy;


#Search for duplicates
SELECT
course_id,
COUNT(course_id) AS dup_count
FROM udemy_course
GROUP BY course_id
HAVING COUNT(course_id) > 1;


#Correct and convert our timestamp from text to datetime
UPDATE udemy_course
SET published_timestamp = 
STR_TO_DATE(REPLACE(REPLACE(published_timestamp, 'T', ' '),'Z', ' '),'%Y-%m-%d %H:%i:%s');

ALTER TABLE udemy_course
MODIFY COLUMN published_timestamp 
DATETIME;


#Total number of courses
SELECT
COUNT(course_id) AS total_course_offered
FROM courses;


#Total number of students
SELECT
SUM(num_subscribers) AS total_student
FROM udemy_course;


#Total number courses, subscribers and reviews by paid and unpaid courses
SELECT
is_paid AS paid_courses,
COUNT(is_paid) AS total_course,
SUM(num_subscribers) AS total_subscribers,
SUM(num_reviews) AS total_reviews
FROM udemy_course
GROUP BY is_paid;


#Total revenue generated
SELECT 
SUM(price*num_subscribers) AS total_revenue
FROM payments;


#Average revenue by subject
SELECT 
SUM(price*num_subscribers) AS total_revenue,
ROUND(AVG(price*num_subscribers),1) AS Avg_revenue,
subject
FROM udemy_course
GROUP BY subject;


#Numbers of subscribers by level
SELECT 
SUM(num_subscribers) AS total_subscribers,
level
FROM udemy_course
GROUP BY level
ORDER BY SUM(num_subscribers) DESC;


#Top 10 most reviewed courses and subject
SELECT 
udemy_course.num_reviews AS total_reviews,
courses.course_title,
udemy_course.subject
FROM udemy_course
RIGHT JOIN courses 
ON udemy_course.course_id = courses.course_id
GROUP BY courses.course_title, udemy_course.num_reviews, udemy_course.subject
ORDER BY udemy_course.num_reviews DESC
LIMIT 10;


#Yearly and monthly revenue trend
SELECT
SUM(price*num_subscribers) AS revenue, 
MONTH(published_timestamp) AS month, 
YEAR(published_timestamp) AS year
FROM udemy_course
GROUP BY month, year;
			
            #yearly
SELECT
SUM(price*num_subscribers) AS revenue, 
YEAR(published_timestamp) AS year
FROM udemy_course
GROUP BY year
ORDER BY revenue DESC;
			
            #monthly
SELECT
SUM(price*num_subscribers) AS revenue, 
MONTH(published_timestamp) AS month 
FROM udemy_course
GROUP BY month
ORDER BY revenue DESC;


#Courses that generated most revenue
SELECT
course_title,
subject,
num_subscribers,
price,
(price*num_subscribers) AS total_revenue,
RANK() OVER(ORDER BY price*num_subscribers DESC) AS revenue_rank
FROM udemy_course
limit 10;


#Top 1 highest earning course per instructor using CTE,ROW_NUMBER,PARTITION BY
WITH earning AS 
(
SELECT
tutors.tutor_id,
payments.course_id,
SUM(price*num_subscribers) AS total_earning,
ROW_NUMBER() OVER (PARTITION BY tutors.tutor_id
ORDER BY SUM(payments.price*num_subscribers) DESC) AS row_num
FROM tutors
JOIN payments
ON tutors.course_id = payments.course_id
GROUP BY tutors.tutor_id, payments.course_id
)
 SELECT*
 FROM earning 
 WHERE row_num=1; 

 
 #Total number of course taken, hours, reviews and lectures taken by each instructor
 WITH instructor AS
 (
 SELECT tutor_id,
 COUNT(reviews.course_id) AS course_taken,
SUM(num_reviews) AS reviews,
ROUND(SUM(content_duration),1) AS total_hours,
SUM(reviews.num_lectures) AS total_lectures
 FROM reviews
 INNER JOIN tutors
 ON tutors.course_id = reviews.course_id
 GROUP BY tutor_id
 ORDER BY COUNT(num_reviews) DESC
 )
 SELECT * 
 FROM instructor;			
 
 
 #Calculate each instructor by their earning
WITH instructors AS
(
SELECT
tutor_id,
ROUND(AVG(payments.price*num_subscribers),1) AS Avg_earning$,  #CHECK BACK LATER ON THIS
SUM(payments.price*num_subscribers) AS earning$,
RANK() OVER (ORDER BY SUM(payments.price*num_subscribers) DESC) AS rank_no
FROM tutors
INNER JOIN payments
ON tutors.course_id = payments.course_id
GROUP BY tutor_id
)
SELECT *
FROM instructors
;
#WHERE tutor_id = 4
  

#Rank course by numbers of reviews and subscribers
SELECT
course_id,
num_reviews AS review,
num_subscribers,
RANK()OVER (ORDER BY num_reviews DESC) AS review_rank,
RANK()OVER (ORDER BY num_subscribers DESC) AS subscribe_rank
FROM reviews
LIMIT 10;
#GROUP BY course_id
 

#Courses with highest number of reviews
SELECT
udemy_course.num_reviews,
udemy_course.num_subscribers,
udemy_course.course_id,
courses.course_title
FROM udemy_course
LEFT JOIN courses
ON udemy_course.course_id = courses.course_id
ORDER BY udemy_course.num_reviews DESC
LIMIT 10;


#Top instructor by revenue USING JOIN
SELECT SUM(payments.price),
tutors.tutor_id
FROM payments
LEFT JOIN tutors
ON payments.course_id = tutors.course_id
GROUP BY tutors.tutor_id
ORDER BY SUM(payments.price) DESC
LIMIT 1; 


#Top performing instructor by enrollment, rating and revenue
SELECT
tutors.tutor_id,
SUM(reviews.num_subscribers) AS total_subscribers,
SUM(reviews.num_reviews) AS total_reviews,
SUM(payments.price*payments.num_subscribers) AS total_revenue
FROM tutors
INNER JOIN reviews
ON tutors.course_id = reviews.course_id
INNER JOIN payments
ON tutors.course_id = payments.course_id
GROUP BY tutor_id
ORDER BY SUM(reviews.num_subscribers) DESC;


#Create view
CREATE VIEW instructor AS
SELECT
tutors.tutor_id,
SUM(reviews.num_subscribers) AS total_subscribers,
SUM(reviews.num_reviews) AS total_reviews,
SUM(payments.price*payments.num_subscribers) AS total_revenue
FROM tutors
INNER JOIN reviews
ON tutors.course_id = reviews.course_id
INNER JOIN payments
ON tutors.course_id = payments.course_id
GROUP BY tutor_id
ORDER BY SUM(reviews.num_subscribers) DESC;
