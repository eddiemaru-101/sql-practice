> GROUP BY 치고 HAVING으로 필터링하면 될거 같았는데 안되네..

## 1단계
> HAVING절에는 집계함수로만 표현할 수 있다  
> 
```
SELECT
    employee_id
    ,department_id
FROM Employee
GROUP BY employee_id
HAVING COUNT(department_id) = 1 
OR primary_flag = "Y";
```
- `OR primary_flag = "Y"`은 집계함수를 사용하지 않았으므로 실행불가

## 2단계 
> 지금 필요한 필터링 조건은 두가지이다.
> 1) department_id가 하나인 경우  
> 2) department_id가 두 개 이상이고, primary_flag=Y인 경우  
> WHERE 절에서 OR로 조건 두개 걸면 안되나? NO, groupby쳐야 집계함수써서 두번째조건 확인가능하므로 WHERE절에 두번째 조건 못넣음  

> 접근법을 바꿔야함! 
```
(조건1) UNION ALL (조건2)   
```
- 적용하면,

```
# Write your MySQL query statement below
SELECT 
    employee_id
    , department_id
FROM Employee
WHERE primary_flag ='Y'

UNION ALL

SELECT 
    employee_id
    , department_id
FROM Employee
GROUP BY employee_id
HAVING COUNT(department_id) = 1;

<result>
| employee_id | department_id |
| ----------- | ------------- |
| 2           | 1             |
| 4           | 3             |
| 1           | 1             |
| 3           | 3             |
```

<br><br><br> 

---

# 1789. Primary Department for Each Employee
```
Table: Employee

+---------------+---------+
| Column Name   |  Type   |
+---------------+---------+
| employee_id   | int     |
| department_id | int     |
| primary_flag  | varchar |
+---------------+---------+
(employee_id, department_id) is the primary key (combination of columns with unique values) for this table.
employee_id is the id of the employee.
department_id is the id of the department to which the employee belongs.
primary_flag is an ENUM (category) of type ('Y', 'N'). If the flag is 'Y', the department is the primary department for the employee. If the flag is 'N', the department is not the primary.
 

Employees can belong to multiple departments. When the employee joins other departments, they need to decide which department is their primary department. Note that when an employee belongs to only one department, their primary column is 'N'.

Write a solution to report all the employees with their primary department. For employees who belong to one department, report their only department.

Return the result table in any order.

The result format is in the following example.

 

Example 1:

Input: 
Employee table:
+-------------+---------------+--------------+
| employee_id | department_id | primary_flag |
+-------------+---------------+--------------+
| 1           | 1             | N            |
| 2           | 1             | Y            |
| 2           | 2             | N            |
| 3           | 3             | N            |
| 4           | 2             | N            |
| 4           | 3             | Y            |
| 4           | 4             | N            |
+-------------+---------------+--------------+
Output: 
+-------------+---------------+
| employee_id | department_id |
+-------------+---------------+
| 1           | 1             |
| 2           | 1             |
| 3           | 3             |
| 4           | 3             |
+-------------+---------------+
Explanation: 
- The Primary department for employee 1 is 1.
- The Primary department for employee 2 is 1.
- The Primary department for employee 3 is 3.
- The Primary department for employee 4 is 3.
```
