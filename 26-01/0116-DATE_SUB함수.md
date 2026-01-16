> 흠.. 2019-07-27일부터 30일간의 날짜 필터링하는 방법에서 막혀버렸다.
---

## 1단계 날짜 필터링
```
-- 첫 작성 쿼리
-- 날짜 필터링에서 막혀버림..ㅜ
SELECT *
FROM Activity
WHERE activity_date between ...
```
### 날짜 범위 필터링 방법 및 함수
- 30일 기간적용하기
  - 2019-06-28 ~ 2019-07-27
```
-- 방법1: BETWEEN 사용
WHERE activity_date BETWEEN '2019-06-28' AND '2019-07-27'

-- 방법2: DATE_SUB 사용 (더 명확)
WHERE activity_date BETWEEN DATE_SUB('2019-07-27', INTERVAL 29 DAY) 
                        AND '2019-07-27'
```
- DATE_SUB함수
```
DATE_SUB
├─ DATE: 날짜
└─ SUB: SUBTRACT (빼다)

의미: 날짜에서 특정 기간을 빼는 함수
```
<br> 
- 적용하면,

```
SELECT *
FROM Activity
WHERE activity_date between DATE_SUB('2019-07-27', Interval 30 DAY) and '2019-07-27';

<result>
| user_id | session_id | activity_date | activity_type |
| ------- | ---------- | ------------- | ------------- |
| 1       | 1          | 2019-07-20    | open_session  |
| 1       | 1          | 2019-07-20    | scroll_down   |
| 1       | 1          | 2019-07-20    | end_session   |
| 2       | 4          | 2019-07-20    | open_session  |
| 2       | 4          | 2019-07-21    | send_message  |
| 2       | 4          | 2019-07-21    | end_session   |
| 3       | 2          | 2019-07-21    | open_session  |
| 3       | 2          | 2019-07-21    | send_message  |
| 3       | 2          | 2019-07-21    | end_session   |
```
<br> 


## 2단계
> 여기는 이전 쿼리에서 배웠던 집계대상은 group by에 기준컬럼으로 넣지 않는거 적용하면 해결!


```
# 정답쿼리
SELECT 
    activity_date AS day
    ,COUNT(DISTINCT user_id) AS active_users
FROM Activity
WHERE activity_date between DATE_SUB('2019-07-27', Interval 30 DAY) and '2019-07-27'
GROUP BY activity_date ;

<result>
| day        | active_users |
| ---------- | ------------ |
| 2019-07-20 | 2            |
| 2019-07-21 | 2            |
```





<br><br>


---
# 1141. User Activity for the Past 30 Days I

```
Table: Activity

+---------------+---------+
| Column Name   | Type    |
+---------------+---------+
| user_id       | int     |
| session_id    | int     |
| activity_date | date    |
| activity_type | enum    |
+---------------+---------+
This table may have duplicate rows.
The activity_type column is an ENUM (category) of type ('open_session', 'end_session', 'scroll_down', 'send_message').
The table shows the user activities for a social media website. 
Note that each session belongs to exactly one user.
 

Write a solution to find the daily active user count for a period of 30 days ending 2019-07-27 inclusively. A user was active on someday if they made at least one activity on that day.

Return the result table in any order.

The result format is in the following example.

Note: Any activity from ('open_session', 'end_session', 'scroll_down', 'send_message') will be considered valid activity for a user to be considered active on a day.

 

Example 1:

Input: 
Activity table:
+---------+------------+---------------+---------------+
| user_id | session_id | activity_date | activity_type |
+---------+------------+---------------+---------------+
| 1       | 1          | 2019-07-20    | open_session  |
| 1       | 1          | 2019-07-20    | scroll_down   |
| 1       | 1          | 2019-07-20    | end_session   |
| 2       | 4          | 2019-07-20    | open_session  |
| 2       | 4          | 2019-07-21    | send_message  |
| 2       | 4          | 2019-07-21    | end_session   |
| 3       | 2          | 2019-07-21    | open_session  |
| 3       | 2          | 2019-07-21    | send_message  |
| 3       | 2          | 2019-07-21    | end_session   |
| 4       | 3          | 2019-06-25    | open_session  |
| 4       | 3          | 2019-06-25    | end_session   |
+---------+------------+---------------+---------------+
Output: 
+------------+--------------+ 
| day        | active_users |
+------------+--------------+ 
| 2019-07-20 | 2            |
| 2019-07-21 | 2            |
+------------+--------------+ 
Explanation: Note that we do not care about days with zero active users.
```
