

### 내가 막힌 단계의 쿼리
- action 컬럼의 값에 따라 어떻게 카운트 하지? 
```
SELECT s.user_id, count/count ??
FROM Signups s
LEFT JOIN Confirmations c
ON s.user_id = c.user_id
GROUP BY s.user_id, c.action;

--일단 이렇게 된 쿼리의 출력결과를 보자 
SELECT *
FROM Signups s
LEFT JOIN Confirmations c
ON s.user_id = c.user_id
GROUP BY s.user_id, c.action;

<result>
| user_id | time_stamp          | user_id | time_stamp          | action    |
| ------- | ------------------- | ------- | ------------------- | --------- |
| 3       | 2020-03-21 10:16:13 | 3       | 2021-07-14 14:00:00 | timeout   |
| 7       | 2020-01-04 13:57:59 | 7       | 2021-06-14 13:59:27 | confirmed |
| 2       | 2020-07-29 23:09:44 | 2       | 2021-02-28 23:59:59 | timeout   |
| 2       | 2020-07-29 23:09:44 | 2       | 2021-01-22 00:00:00 | confirmed |
| 6       | 2020-12-09 10:39:37 | null    | null                | null      |
```

### 1단계 
- GROUP BY 수정하기
- action으로 groupby하면 안되고 IF문으로 조건에 따른 카운트로 뺴야함
- IF(조건, 참일 때 값, 거짓일 때 값) 형식을 지켜야 함  
```
-- 수정 전
SELECT *
FROM Signups s
LEFT JOIN Confirmations c
ON s.user_id = c.user_id
GROUP BY s.user_id;

<result>
| user_id | time_stamp          | user_id | time_stamp          | action    |
| ------- | ------------------- | ------- | ------------------- | --------- |
| 3       | 2020-03-21 10:16:13 | 3       | 2021-07-14 14:00:00 | timeout   |
| 7       | 2020-01-04 13:57:59 | 7       | 2021-06-14 13:59:27 | confirmed |
| 2       | 2020-07-29 23:09:44 | 2       | 2021-02-28 23:59:59 | timeout   |
| 6       | 2020-12-09 10:39:37 | null    | null                | null      |

-- 수정 후
SELECT s.user_id
    , SUM(IF(c.action='confirmed',1,0))/count(s.user_id) AS confirmation_rate
FROM Signups s
LEFT JOIN Confirmations c
ON s.user_id = c.user_id
GROUP BY s.user_id;

<result>
| user_id | confirmation_rate |
| ------- | ----------------- |
| 3       | 0                 |
| 7       | 1                 |
| 2       | 0.5               |
| 6       | 0                 |
```

### 3단계 - 출력 디테일 챙기기
> 2단계로도 통과는 되지만 좀더 디테일을 챙겨보자  
- 문제의 출력결과는 소수점 2자리이다. -> ROUND(값, 소수점자릿수)
```
# Write your MySQL query statement below
SELECT s.user_id
    , ROUND(SUM(IF(c.action='confirmed',1,0))/count(s.user_id),2) AS confirmation_rate
FROM Signups s
LEFT JOIN Confirmations c
ON s.user_id = c.user_id
GROUP BY s.user_id;

<result>
| user_id | confirmation_rate |
| ------- | ----------------- |
| 3       | 0                 |
| 7       | 1                 |
| 2       | 0.5               |
| 6       | 0                 |

-- 어랏? 왜 안되지?
```
> round로 감싸도 안에 sum, count가 정수로 만들어서 처리하기 때문, float로 바꿔줘야함
```
SELECT s.user_id
    , ROUND(SUM(IF(c.action='confirmed',1,0)) * 1.0 / COUNT(s.user_id), 2) AS confirmation_rate
FROM Signups s
LEFT JOIN Confirmations c ON s.user_id = c.user_id
GROUP BY s.user_id;

<result>
| user_id | confirmation_rate |
| ------- | ----------------- |
| 3       | 0                 |
| 7       | 1                 |
| 2       | 0.5               |
| 6       | 0                 |

-- ?? 똑같은데?
```
> (젬미니)계산 로직은 맞는데 소수점 자리수가 고정되지 않는 문제는 사용 중인 DB 엔진(MySQL 등)이 "값이 0.5면 0.50이나 0.5나 같으니 짧게 보여주자"라고 판단해서 생기는 현상입니다.
>  -> 그냥 같으니까 그대로 써라 !!

### 좀더 세련된 방식의 접근법
- AVG함수 활용
```
SELECT s.user_id
    , ROUND(AVG(IF(c.action='confirmed', 1, 0)), 2) AS confirmation_rate
FROM Signups s
LEFT JOIN Confirmations c ON s.user_id = c.user_id
GROUP BY s.user_id;

<result>
| user_id | confirmation_rate |
| ------- | ----------------- |
| 3       | 0                 |
| 7       | 1                 |
| 2       | 0.5               |
| 6       | 0                 |
```

# 1934. Confirmation Rate
```
Table: Signups

+----------------+----------+
| Column Name    | Type     |
+----------------+----------+
| user_id        | int      |
| time_stamp     | datetime |
+----------------+----------+
user_id is the column of unique values for this table.
Each row contains information about the signup time for the user with ID user_id.
 

Table: Confirmations

+----------------+----------+
| Column Name    | Type     |
+----------------+----------+
| user_id        | int      |
| time_stamp     | datetime |
| action         | ENUM     |
+----------------+----------+
(user_id, time_stamp) is the primary key (combination of columns with unique values) for this table.
user_id is a foreign key (reference column) to the Signups table.
action is an ENUM (category) of the type ('confirmed', 'timeout')
Each row of this table indicates that the user with ID user_id requested a confirmation message at time_stamp and that confirmation message was either confirmed ('confirmed') or expired without confirming ('timeout').
 

The confirmation rate of a user is the number of 'confirmed' messages divided by the total number of requested confirmation messages. The confirmation rate of a user that did not request any confirmation messages is 0. Round the confirmation rate to two decimal places.

Write a solution to find the confirmation rate of each user.

Return the result table in any order.

The result format is in the following example.

 

Example 1:

Input: 
Signups table:
+---------+---------------------+
| user_id | time_stamp          |
+---------+---------------------+
| 3       | 2020-03-21 10:16:13 |
| 7       | 2020-01-04 13:57:59 |
| 2       | 2020-07-29 23:09:44 |
| 6       | 2020-12-09 10:39:37 |
+---------+---------------------+
Confirmations table:
+---------+---------------------+-----------+
| user_id | time_stamp          | action    |
+---------+---------------------+-----------+
| 3       | 2021-01-06 03:30:46 | timeout   |
| 3       | 2021-07-14 14:00:00 | timeout   |
| 7       | 2021-06-12 11:57:29 | confirmed |
| 7       | 2021-06-13 12:58:28 | confirmed |
| 7       | 2021-06-14 13:59:27 | confirmed |
| 2       | 2021-01-22 00:00:00 | confirmed |
| 2       | 2021-02-28 23:59:59 | timeout   |
+---------+---------------------+-----------+
Output: 
+---------+-------------------+
| user_id | confirmation_rate |
+---------+-------------------+
| 6       | 0.00              |
| 3       | 0.00              |
| 7       | 1.00              |
| 2       | 0.50              |
+---------+-------------------+
Explanation: 
User 6 did not request any confirmation messages. The confirmation rate is 0.
User 3 made 2 requests and both timed out. The confirmation rate is 0.
User 7 made 3 requests and all were confirmed. The confirmation rate is 1.
User 2 made 2 requests where one was confirmed and the other timed out. The confirmation rate is 1 / 2 = 0.5.
```
