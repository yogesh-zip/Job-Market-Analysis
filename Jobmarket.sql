use jobmarket;
select count(*) from jobmarket;
-- **Block 1 — Replace -1 with NULL: --
UPDATE jobmarket SET Rating = NULL WHERE Rating = -1;
UPDATE jobmarket SET Founded = NULL WHERE Founded = -1;
UPDATE jobmarket SET Hourly = NULL WHERE Hourly = -1;
UPDATE jobmarket SET Employer_provided = NULL WHERE Employer_provided = -1;
UPDATE jobmarket SET Lower_Salary = NULL WHERE Lower_Salary = -1;
UPDATE jobmarket SET Upper_Salary = NULL WHERE Upper_Salary = -1;
UPDATE jobmarket SET Avg_SalaryK = NULL WHERE Avg_SalaryK = -1;
UPDATE jobmarket SET Python = NULL WHERE Python = -1;
UPDATE jobmarket SET spark = NULL WHERE spark = -1;
UPDATE jobmarket SET aws = NULL WHERE aws = -1;
UPDATE jobmarket SET excel = NULL WHERE excel = -1;
UPDATE jobmarket SET sql_ = NULL WHERE sql_ = -1;
UPDATE jobmarket SET sas = NULL WHERE sas = -1;
UPDATE jobmarket SET keras = NULL WHERE keras = -1;
UPDATE jobmarket SET pytorch = NULL WHERE pytorch = -1;
UPDATE jobmarket SET scikit = NULL WHERE scikit = -1;
UPDATE jobmarket SET tensor = NULL WHERE tensor = -1;
UPDATE jobmarket SET hadoop = NULL WHERE hadoop = -1;
UPDATE jobmarket SET tableau = NULL WHERE tableau = -1;
UPDATE jobmarket SET bi = NULL WHERE bi = -1;
UPDATE jobmarket SET flink = NULL WHERE flink = -1;
UPDATE jobmarket SET mongo = NULL WHERE mongo = -1;
UPDATE jobmarket SET google_an = NULL WHERE google_an = -1;

-- Compute avg salary where missing
UPDATE jobmarket
SET Avg_SalaryK = ROUND((Lower_Salary + Upper_Salary) / 2, 2)
WHERE Avg_SalaryK IS NULL
  AND Lower_Salary IS NOT NULL
  AND Upper_Salary IS NOT NULL;

-- Extract state from location (format: "City, ST")
ALTER TABLE jobmarket ADD COLUMN state CHAR(2);

UPDATE jobmarket
SET state = TRIM(SUBSTRING_INDEX(Location, ',', -1))
WHERE Location LIKE '%,%';

SELECT
COUNT(*)   AS totsl_rows,
SUM( CASE WHEN Avg_SalaryK IS NULL THEN 1 END) AS null_salary,
SUM( CASE WHEN Rating IS NULL THEN 1 END) AS null_rating,
SUM( CASE WHEN State IS NULL THEN 1 END) AS null_state
FROM jobmarket;

-- State with most no of jobs
SELECT
    state,
    COUNT(*) AS job_count
FROM jobmarket
WHERE state IS NOT NULL
GROUP BY state
ORDER BY job_count DESC
LIMIT 15;

-- Average min and max salary in diff states

SELECT
    state,
    ROUND(AVG(Lower_Salary), 1) AS avg_min_salary_k,
    ROUND(AVG(Upper_Salary), 1) AS avg_max_salary_k
FROM jobmarket
WHERE state IS NOT NULL
  AND Lower_Salary IS NOT NULL
  AND Upper_Salary IS NOT NULL
GROUP BY state
ORDER BY avg_max_salary_k DESC
LIMIT 15;

-- Average salary by state

SELECT
    state,
    ROUND(AVG(Avg_SalaryK), 1) AS avg_salary_k
FROM jobmarket
WHERE state IS NOT NULL
  AND Avg_SalaryK IS NOT NULL
GROUP BY state
ORDER BY avg_salary_k DESC
LIMIT 15;

-- Top 5 industries with most no of data science jobs

SELECT
    Industry,
    COUNT(*) AS job_count
FROM jobmarket
WHERE Industry IS NOT NULL
  AND (
        LOWER(Job_Title) LIKE '%data scientist%'
     OR LOWER(Job_Title) LIKE '%data science%'
     OR LOWER(Job_Title) LIKE '%machine learning%'
     OR LOWER(Job_Title) LIKE '%data analyst%'
     OR LOWER(job_title_sim) LIKE '%data scientist%'
  )
GROUP BY Industry
ORDER BY job_count DESC
LIMIT 5;

-- Companies with Most Job Openings

SELECT
    company_txt AS company,
    COUNT(*) AS job_openings
FROM jobmarket
WHERE company_txt IS NOT NULL
GROUP BY company_txt
ORDER BY job_openings DESC
LIMIT 10;

-- Job Titles with Most Number of Jobs

SELECT
    job_title_sim AS job_title,
    COUNT(*) AS job_count
FROM jobmarket
WHERE job_title_sim IS NOT NULL
GROUP BY job_title_sim
ORDER BY job_count DESC
LIMIT 10;

--  Salary of Those Top Job Titles

SELECT
    j.job_title_sim                    AS job_title,
    COUNT(*)                           AS job_count,
    ROUND(AVG(j.Avg_SalaryK), 1)       AS avg_salary_k,
    ROUND(AVG(j.Lower_Salary), 1)      AS avg_min_salary_k,
    ROUND(AVG(j.Upper_Salary), 1)      AS avg_max_salary_k
FROM jobmarket j
INNER JOIN (
    SELECT job_title_sim
    FROM jobmarket
    WHERE job_title_sim IS NOT NULL
    GROUP BY job_title_sim
    ORDER BY COUNT(*) DESC
    LIMIT 10
) top_titles ON j.job_title_sim = top_titles.job_title_sim
WHERE j.Avg_SalaryK IS NOT NULL
GROUP BY j.job_title_sim
ORDER BY avg_salary_k DESC;

-- Skills Required per Job Title

SELECT
    job_title_sim                               AS job_title,
    COUNT(*)                                    AS total_jobs,
    ROUND(SUM(Python) / COUNT(*) * 100, 1)      AS python_pct,
    ROUND(SUM(sql_) / COUNT(*) * 100, 1)        AS sql_pct,
    ROUND(SUM(aws) / COUNT(*) * 100, 1)         AS aws_pct,
    ROUND(SUM(excel) / COUNT(*) * 100, 1)       AS excel_pct,
    ROUND(SUM(spark) / COUNT(*) * 100, 1)       AS spark_pct,
    ROUND(SUM(tableau) / COUNT(*) * 100, 1)     AS tableau_pct,
    ROUND(SUM(tensor) / COUNT(*) * 100, 1)      AS tensorflow_pct,
    ROUND(SUM(keras) / COUNT(*) * 100, 1)       AS keras_pct,
    ROUND(SUM(pytorch) / COUNT(*) * 100, 1)     AS pytorch_pct,
    ROUND(SUM(hadoop) / COUNT(*) * 100, 1)      AS hadoop_pct
FROM jobmarket
WHERE job_title_sim IS NOT NULL
GROUP BY job_title_sim
HAVING total_jobs >= 10
ORDER BY total_jobs DESC
LIMIT 10;

-- Salary vs Education

SELECT
    CASE
        WHEN Degree = 'M' THEN 'Masters'
        WHEN Degree = 'P' THEN 'PhD'
        ELSE 'Not Specified'
    END                             AS education_level,
    COUNT(*)                        AS job_count,
    ROUND(AVG(Avg_SalaryK), 1)      AS avg_salary_k,
    ROUND(MIN(Avg_SalaryK), 1)      AS min_salary_k,
    ROUND(MAX(Avg_SalaryK), 1)      AS max_salary_k
FROM jobmarket
WHERE Avg_SalaryK IS NOT NULL
GROUP BY education_level
ORDER BY avg_salary_k DESC;

-- Seniority vs Average Salary

SELECT
    seniority_by_title              AS seniority,
    COUNT(*)                        AS job_count,
    ROUND(AVG(Avg_SalaryK), 1)      AS avg_salary_k,
    ROUND(MIN(Avg_SalaryK), 1)      AS min_salary_k,
    ROUND(MAX(Avg_SalaryK), 1)      AS max_salary_k
FROM jobmarket
WHERE seniority_by_title IS NOT NULL
  AND Avg_SalaryK IS NOT NULL
GROUP BY seniority_by_title
ORDER BY avg_salary_k DESC;

-- Top Sectors by Job Count

SELECT
    Sector,
    COUNT(*) AS job_count
FROM jobmarket
WHERE Sector IS NOT NULL
GROUP BY Sector
ORDER BY job_count DESC
LIMIT 10;



SELECT
    Type_of_ownership,
    COUNT(*) AS job_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM jobmarket), 1) AS percentage
FROM jobmarket
WHERE Type_of_ownership IS NOT NULL
GROUP BY Type_of_ownership
ORDER BY job_count DESC;

-- Most In-Demand Skills Overall

SELECT 'Python'           AS skill, SUM(COALESCE(Python, 0)) AS demand_count FROM jobmarket
UNION ALL
SELECT 'SQL'              AS skill, SUM(COALESCE(sql_, 0))   FROM jobmarket
UNION ALL
SELECT 'Excel'            AS skill, SUM(COALESCE(excel, 0))  FROM jobmarket
UNION ALL
SELECT 'AWS'              AS skill, SUM(COALESCE(aws, 0))    FROM jobmarket
UNION ALL
SELECT 'Spark'            AS skill, SUM(COALESCE(spark, 0))  FROM jobmarket
UNION ALL
SELECT 'Tableau'          AS skill, SUM(COALESCE(tableau, 0)) FROM jobmarket
UNION ALL
SELECT 'TensorFlow'       AS skill, SUM(COALESCE(tensor, 0)) FROM jobmarket
UNION ALL
SELECT 'Keras'            AS skill, SUM(COALESCE(keras, 0))  FROM jobmarket
UNION ALL
SELECT 'PyTorch'          AS skill, SUM(COALESCE(pytorch, 0)) FROM jobmarket
UNION ALL
SELECT 'Hadoop'           AS skill, SUM(COALESCE(hadoop, 0)) FROM jobmarket
UNION ALL
SELECT 'SAS'              AS skill, SUM(COALESCE(sas, 0))    FROM jobmarket
UNION ALL
SELECT 'Power BI'         AS skill, SUM(COALESCE(bi, 0))     FROM jobmarket
UNION ALL
SELECT 'MongoDB'          AS skill, SUM(COALESCE(mongo, 0))  FROM jobmarket
UNION ALL
SELECT 'Google Analytics' AS skill, SUM(COALESCE(google_an, 0)) FROM jobmarket
ORDER BY demand_count DESC;

select * from jobmarket;