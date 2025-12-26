> where절, Having절의 차이  
> 그래도 SELF JOIN으로 푸는걸로 접근함

## 570. Managers with at Least 5 Direct Reports
```
Table: Employee

+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| id          | int     |
| name        | varchar |
| department  | varchar |
| managerId   | int     |
+-------------+---------+
id is the primary key (column with unique values) for this table.
Each row of this table indicates the name of an employee, their department, and the id of their manager.
If managerId is null, then the employee does not have a manager.
No employee will be the manager of themself.
 

Write a solution to find managers with at least five direct reports.

Return the result table in any order.

The result format is in the following example.

 

Example 1:

Input: 
Employee table:
+-----+-------+------------+-----------+
| id  | name  | department | managerId |
+-----+-------+------------+-----------+
| 101 | John  | A          | null      |
| 102 | Dan   | A          | 101       |
| 103 | James | A          | 101       |
| 104 | Amy   | A          | 101       |
| 105 | Anne  | A          | 101       |
| 106 | Ron   | B          | 101       |
+-----+-------+------------+-----------+
Output: 
+------+
| name |
+------+
| John |
+------+
```
## 정답1
```
SELECT e.name
FROM Employee e
JOIN Employee m 
ON e.id = m.managerId
HAVING COUNT(e.department)>=5;

| name |
| ---- |
| John |
```
## 정답2(서브쿼리)
> 이게 더 직관적이라고 하는데
> 모르겠다. 아직 서브쿼리를 많이 안써서 익숙하지 않음  
```
-- 방법 1: 서브쿼리 (가장 직관적)
SELECT name
FROM Employee
WHERE id IN (
    SELECT managerId
    FROM Employee
    WHERE managerId IS NOT NULL
    GROUP BY managerId
    HAVING COUNT(*) >= 5
);

- 읽기 쉬움 - "id가 (5명 이상 부하 가진 매니저 목록)에 있으면"
- IN 서브쿼리는 엔진이 잘 최적화함
- 코드가 짧고 의도가 명확함
```

### 삽질하던 쿼리
```
SELECT *
FROM Employee e1
LEFT JOIN Employee e2
ON e1.id = e2.managerID;
| id  | name  | department | managerId | id   | name  | department | managerId |
| --- | ----- | ---------- | --------- | ---- | ----- | ---------- | --------- |
| 101 | John  | A          | null      | 106  | Ron   | B          | 101       |
| 101 | John  | A          | null      | 105  | Anne  | A          | 101       |
| 101 | John  | A          | null      | 104  | Amy   | A          | 101       |
| 101 | John  | A          | null      | 103  | James | A          | 101       |
| 101 | John  | A          | null      | 102  | Dan   | A          | 101       |
| 102 | Dan   | A          | 101       | null | null  | null       | null      |
| 103 | James | A          | 101       | null | null  | null       | null      |
| 104 | Amy   | A          | 101       | null | null  | null       | null      |
| 105 | Anne  | A          | 101       | null | null  | null       | null      |
| 106 | Ron   | B          | 101       | null | null  | null       | null      |
```
```
SELECT *
FROM Employee e1
JOIN Employee e2
ON e1.id = e2.managerID;

| id  | name | department | managerId | id  | name  | department | managerId |
| --- | ---- | ---------- | --------- | --- | ----- | ---------- | --------- |
| 101 | John | A          | null      | 102 | Dan   | A          | 101       |
| 101 | John | A          | null      | 103 | James | A          | 101       |
| 101 | John | A          | null      | 104 | Amy   | A          | 101       |
| 101 | John | A          | null      | 105 | Anne  | A          | 101       |
| 101 | John | A          | null      | 106 | Ron   | B          | 101       |

```
