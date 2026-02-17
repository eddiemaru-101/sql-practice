> 흠.. requester_id, accepted_id 따로 그룹바이해서 union all 해야하나 ?  
> 하지만 그전에 항상 이런 생각을 가져여한다!  
> "테이블 각각 집계하는것보다   
> 하나의 테이블에 만든다음 집계하는게 훨씬 더 문제를 단순하게 만든다" 

-> 앞선 생각으로 접근하면 항상 다음과 같은 문제가 발생한다.  
```
각각 집계 → 합치기
(복잡, NULL 처리, JOIN 타입 고민)
```
<br> 

 ## 1단계 UNION ALL로 하나의 컬럼으로 합치기 

```
SELECT accepter_id
FROM RequestAccepted

UNION ALL

SELECT requester_id
FROM RequestAccepted;


| accepter_id |
| ----------- |
| 2           |
| 3           |
| 3           |
| 4           |
| 1           |
| 1           |
| 2           |
| 3           |

"UNION ALL에서 컬럼명은 첫 번째 SELECT 기준으로 결정돼."
"그래서 지금 결과 컬럼명은 accepter_id야."
```
- 세로로 붙이는건 UNIOB ALL
- 가로로 붙이는건 JOIN

```

UNION ALL → 행을 추가 (세로)
JOIN      → 컬럼을 추가 (가로)

-- UNION ALL: 세로
1
2
3
---
4
5
6


-- JOIN: 가로
1 | A
2 | B
3 | C
```
<br><br>

## 2단계 - 그룹/COUNT/DESC/LIMIT 1
> 일단 WITH문으로 가독성 높게 작성함!

- 정답쿼리
```
WITH count_fr AS (SELECT accepter_id AS id
FROM RequestAccepted
UNION ALL
SELECT requester_id AS id
FROM RequestAccepted )

SELECT 
    id,
    COUNT(id) AS num
FROM count_fr
GROUP BY id
ORDER BY num DESC
LIMIT 1;


<result>
| id | num |
| -- | --- |
| 3  | 3   |
```
<br><br>

## 3단계 추가지식
> 이제 조금씩 더 챙겨보자.
> COUNT(*), COUNT(id) 뭘하든 결과는 같다. 하지만 null이 있는 행에서는 다르다.
- COUNT(*) - NULL 포함
- COUNT(id) - NULL 제외 
```
SELECT 
    COUNT(*)    AS total,   -- 행 자체를 셈
    COUNT(name) AS has_name -- NULL 제외하고 셈
FROM users;
```
<br><br><br>


# 602. Friend Requests II: Who Has the Most Friends
```
Table: RequestAccepted

+----------------+---------+
| Column Name    | Type    |
+----------------+---------+
| requester_id   | int     |
| accepter_id    | int     |
| accept_date    | date    |
+----------------+---------+
(requester_id, accepter_id) is the primary key (combination of columns with unique values) for this table.
This table contains the ID of the user who sent the request, the ID of the user who received the request, and the date when the request was accepted.
 

Write a solution to find the people who have the most friends and the most friends number.

The test cases are generated so that only one person has the most friends.

The result format is in the following example.

 

Example 1:

Input: 
RequestAccepted table:
+--------------+-------------+-------------+
| requester_id | accepter_id | accept_date |
+--------------+-------------+-------------+
| 1            | 2           | 2016/06/03  |
| 1            | 3           | 2016/06/08  |
| 2            | 3           | 2016/06/08  |
| 3            | 4           | 2016/06/09  |
+--------------+-------------+-------------+
Output: 
+----+-----+
| id | num |
+----+-----+
| 3  | 3   |
+----+-----+
Explanation: 
The person with id 3 is a friend of people 1, 2, and 4, so he has three friends in total, which is the most number than any others.

```
