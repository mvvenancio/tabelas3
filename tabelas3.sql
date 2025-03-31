CREATE DATABASE tabelas3;
USE tabelas3;
CREATE TABLE students (
    id INT PRIMARY KEY,
    name TEXT NOT NULL,
    enrolled_at DATE NOT NULL,
    course_id TEXT NOT NULL
);

CREATE TABLE courses (
    id VARCHAR(255) PRIMARY KEY,
    name TEXT NOT NULL,
    price NUMERIC NOT NULL,
    school_id TEXT NOT NULL
);

CREATE TABLE schools (
    id VARCHAR(255) PRIMARY KEY,
    name TEXT NOT NULL
); 

INSERT INTO students (id, name, enrolled_at, course_id)
VALUES
    (1, 'João Silva', '2023-01-15', 'C1'),
    (2, 'Maria Oliveira', '2023-02-20', 'C2'),
    (3, 'Carlos Pereira', '2023-03-10', 'C3'),
    (4, 'Ana Souza', '2023-04-12', 'C1'),
    (5, 'Paulo Santos', '2023-05-25', 'C2');

INSERT INTO courses (id, name, price, school_id)
VALUES
    ('C1', 'Engenharia de Software', 1500, 'S1'),
    ('C2', 'Administração', 1200, 'S2'),
    ('C3', 'Medicina', 2500, 'S3');

INSERT INTO schools (id, name)
VALUES
    ('S1', 'Universidade de São Paulo'),
    ('S2', 'Universidade Estadual de Florianópolis'),
    ('S3', 'Universidade Federal de Minas Gerais');

SELECT 
    s.name AS school_name,
    DATE(st.enrolled_at) AS enrollment_date,
    COUNT(st.id) AS num_students,
    SUM(c.price) AS total_revenue
FROM
    students st
JOIN
    courses c ON st.course_id = c.id
JOIN
    schools s ON c.school_id = s.id
GROUP BY 
    s.name, DATE(st.enrolled_at)
ORDER BY 
    enrollment_date DESC;
    
SELECT
    school_name,
    enrolled_date,
    student_count,
    cumulative_students,
    avg_7_days,
    avg_30_days
FROM (
    SELECT
        s.name AS school_name,
        DATE(st.enrolled_at) AS enrolled_date,
        COUNT(st.id) AS student_count,
        @cumulative_students := IF(@current_school = s.name, @cumulative_students + COUNT(st.id), COUNT(st.id)) AS cumulative_students,
        @current_school := s.name,
        s.id AS school_id, -- Incluímos explicitamente s.id aqui
        @row_num := IF(@current_school = s.name, @row_num + 1, 1) AS row_num
    FROM
        students st
    JOIN
        courses c ON st.course_id = c.id
    JOIN
        schools s ON c.school_id = s.id,
        (SELECT @cumulative_students := 0, @current_school := '', @row_num := 0) AS vars
    WHERE
        st.enrolled_at >= '2023-01-01'
        AND st.enrolled_at < '2024-01-01'
    GROUP BY
        s.name, enrolled_date, s.id -- Adicionamos s.id ao GROUP BY
    ORDER BY
        s.name, enrolled_date
) AS calculated_values
LEFT JOIN ( -- mudamos o join para LEFT JOIN
    SELECT
        school_id,
        AVG(student_count) AS avg_7_days
    FROM (
        SELECT
            c2.school_id AS school_id,
            DATE(st2.enrolled_at) AS enrolled_at,
            COUNT(st2.id) AS student_count
        FROM
            students st2
        JOIN
            courses c2 ON st2.course_id = c2.id
        GROUP BY
            c2.school_id, DATE(st2.enrolled_at)
        ORDER BY
            enrolled_at DESC
        LIMIT 7
    ) AS sub
    GROUP BY school_id
) AS avg7 ON calculated_values.school_id = avg7.school_id
LEFT JOIN (
    SELECT
        school_id,
        AVG(student_count) AS avg_30_days
    FROM (
        SELECT
            c3.school_id AS school_id,
            DATE(st3.enrolled_at) AS enrolled_at,
            COUNT(st3.id) AS student_count
        FROM
            students st3
        JOIN
            courses c3 ON st3.course_id = c3.id
        GROUP BY
            c3.school_id, DATE(st3.enrolled_at)
        ORDER BY
            enrolled_at DESC
        LIMIT 30
    ) AS sub2
    GROUP BY school_id
) AS avg30 ON calculated_values.school_id = avg30.school_id
ORDER BY
    school_name, enrolled_date;