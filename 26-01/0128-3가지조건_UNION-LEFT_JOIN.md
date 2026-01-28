> 흠 세가지 조건, 게다가 각각 집계함수를 써야함.
> UNION으로 풀었다.


## 1단계 - 3가지 조건 UNION으로 
> 통과되긴 했음.
> 작동은 하는데, 문제는 각 카테고리마다 같은 테이블을 세 번 스캔해서 비효율적임. 

- 정답쿼리
```
SELECT 'Low Salary' as category, COUNT(*) as accounts_count
FROM Accounts
WHERE income < 20000
UNION
SELECT 'Average Salary', COUNT(*)
FROM Accounts
WHERE income BETWEEN 20000 AND 50000
UNION
SELECT 'High Salary', COUNT(*)
FROM Accounts
WHERE income > 50000;


| category       | accounts_count |
| -------------- | -------------- |
| Low Salary     | 1              |
| Average Salary | 0              |
| High Salary    | 3              |
```
<br><br>


## 2단계 - 쿼리튜닝 
> 테이블을 1번만 스캔하는 다른 방법을 알아보자.

- (잘못된쿼리) 가장 쉬운접근, 하지만 '0'표현 안됨
```
SELECT 
    CASE 
        WHEN income < 20000 THEN 'Low Salary'
        WHEN income BETWEEN 20000 AND 50000 THEN 'Average Salary'
        ELSE 'High Salary'
    END as category,
    COUNT(*) as accounts_count
FROM Accounts
GROUP BY category;

| category    | accounts_count |
| ----------- | -------------- |
| High Salary | 3              |
| Low Salary  | 1              |
```
- 'Average Salary' 0값이 표현 안됨.
- 그래서 앞에 빈 카테고리 만들어주면! 될거 같지만! 
```
-- 먼저 빈 카테고리 만들기
SELECT 'Low Salary' as category, 0 as accounts_count
UNION
SELECT 'Average Salary', 0
UNION  
SELECT 'High Salary', 0
UNION
SELECT 
    CASE 
        WHEN income < 20000 THEN 'Low Salary'
        WHEN income BETWEEN 20000 AND 50000 THEN 'Average Salary'
        ELSE 'High Salary'
    END as category,
    COUNT(*) as accounts_count
FROM Accounts
GROUP BY category;


| category       | accounts_count |
| -------------- | -------------- |
| Low Salary     | 0              |
| Average Salary | 0              |
| High Salary    | 0              |
| High Salary    | 3              |
| Low Salary     | 1              |
```
- 이렇게 동적으로 적용이 안됨!

> 다른 접근법이 필요하다!

### 방법 B (CTE + LEFT JOIN)
- Accounts 테이블 1번만 스캔
- categorized_accounts 만들 때 한 번만 읽음
- 훨씬 효율적
```
-- 방법 B: 고정 카테고리 테이블 + LEFT JOIN
WITH categories AS (
    SELECT 'Low Salary' as category
    UNION
    SELECT 'Average Salary'
    UNION
    SELECT 'High Salary'
),
categorized_accounts AS (
    SELECT 
        CASE 
            WHEN income < 20000 THEN 'Low Salary'
            WHEN income BETWEEN 20000 AND 50000 THEN 'Average Salary'
            ELSE 'High Salary'
        END as category
    FROM Accounts
)
SELECT 
    c.category,
    COUNT(ca.category) as accounts_count
FROM categories c
LEFT JOIN categorized_accounts ca ON c.category = ca.category
GROUP BY c.category;


| category       | accounts_count |
| -------------- | -------------- |
| Low Salary     | 1              |
| Average Salary | 0              |
| High Salary    | 3              |
```
> 어떻게 ? 

```
WITH categories AS (
    SELECT 'Low Salary' as category
    UNION
    SELECT 'Average Salary'
    UNION
    SELECT 'High Salary'
)
SELECT * FROM categories;

-- 실행하면:
| category       |
| -------------- |
| Low Salary     |
| Average Salary |
| High Salary    |
```
```
WITH categorized_accounts AS (
    SELECT 
        CASE 
            WHEN income < 20000 THEN 'Low Salary'
            WHEN income BETWEEN 20000 AND 50000 THEN 'Average Salary'
            ELSE 'High Salary'
        END as category
    FROM Accounts
)
SELECT * FROM categorized_accounts;


-- 실행하면:
| category    |
| ----------- |
| High Salary |  -- account_id 3
| Low Salary  |  -- account_id 2
| High Salary |  -- account_id 8
| High Salary |  -- account_id 6
```
```
SELECT 
    c.category,
    COUNT(ca.category) as accounts_count
FROM categories c
LEFT JOIN categorized_accounts ca ON c.category = ca.category
GROUP BY c.category;

-- 조인 후 상태를 생각해보면:

categories         categorized_accounts
| Low Salary    |  JOIN  | Low Salary  |     -- 매칭 1개
| Average Salary|  JOIN  | NULL        |     -- 매칭 0개
| High Salary   |  JOIN  | High Salary |     -- 매칭 3개
                         | High Salary |
                         | High Salary |
```












<br><br><br><br> 


---
# 1907. Count Salary Categories
```
Table: Accounts

+-------------+------+
| Column Name | Type |
+-------------+------+
| account_id  | int  |
| income      | int  |
+-------------+------+
account_id is the primary key (column with unique values) for this table.
Each row contains information about the monthly income for one bank account.
 

Write a solution to calculate the number of bank accounts for each salary category. The salary categories are:

"Low Salary": All the salaries strictly less than $20000.
"Average Salary": All the salaries in the inclusive range [$20000, $50000].
"High Salary": All the salaries strictly greater than $50000.
The result table must contain all three categories. If there are no accounts in a category, return 0.

Return the result table in any order.

The result format is in the following example.

 

Example 1:

Input: 
Accounts table:
+------------+--------+
| account_id | income |
+------------+--------+
| 3          | 108939 |
| 2          | 12747  |
| 8          | 87709  |
| 6          | 91796  |
+------------+--------+
Output: 
+----------------+----------------+
| category       | accounts_count |
+----------------+----------------+
| Low Salary     | 1              |
| Average Salary | 0              |
| High Salary    | 3              |
+----------------+----------------+
Explanation: 
Low Salary: Account 2.
Average Salary: No accounts.
High Salary: Accounts 3, 6, and 8.
```
