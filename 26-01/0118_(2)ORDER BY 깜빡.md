> 이것도 한 번에 푸는줄 알았으나,, 한 번 막힘


## 1단계 - GROUP BY하면 끝나는줄..
> 1차 예제 통과, 2차 풀테스트(?)에서 막힘
> 2차 풀테스트? 용어가 뭔지 모르곘네 ..

```
SELECT 
    user_id
    ,count(follower_id) AS followers_count
FROM Followers
GROUP BY user_id;

<result>
| user_id | followers_count |
| ------- | --------------- |
| 0       | 1               |
| 1       | 1               |
| 2       | 2               |
```

## 2단계 - 놓친부분 체크하기 
- 풀테스트 결과
```
-- 내 결과값
| user_id | followers_count |
| ------- | --------------- |
| 39      | 1               |
| 20      | 1               |
| 54      | 1               |
| 17      | 1               |
| 78      | 2               |
| 56      | 1               |
| 98      | 1               |
| 77      | 1               |
| 82      | 1               |

-- 기대한 결과값
| user_id | followers_count |
| ------- | --------------- |
| 17      | 1               |
| 20      | 1               |
| 39      | 1               |
| 54      | 1               |
| 56      | 1               |
| 77      | 1               |
| 78      | 2               |
| 82      | 1               |
| 98      | 1               |
```
<br>

> 윽.. 민망하게도 그냥 ORDER BY 안한거였다...

```
-- 정답쿼리

SELECT 
    user_id
    ,count(follower_id) AS followers_count
FROM Followers
GROUP BY user_id
ORDER BY user_id ASC;

<result>
| user_id | followers_count |
| ------- | --------------- |
| 0       | 1               |
| 1       | 1               |
| 2       | 2               |
```


<br><br>

---

# 1729. Find Followers Count
```
Table: Followers

+-------------+------+
| Column Name | Type |
+-------------+------+
| user_id     | int  |
| follower_id | int  |
+-------------+------+
(user_id, follower_id) is the primary key (combination of columns with unique values) for this table.
This table contains the IDs of a user and a follower in a social media app where the follower follows the user.
 

Write a solution that will, for each user, return the number of followers.

Return the result table ordered by user_id in ascending order.

The result format is in the following example.

 

Example 1:

Input: 
Followers table:
+---------+-------------+
| user_id | follower_id |
+---------+-------------+
| 0       | 1           |
| 1       | 0           |
| 2       | 0           |
| 2       | 1           |
+---------+-------------+
Output: 
+---------+----------------+
| user_id | followers_count|
+---------+----------------+
| 0       | 1              |
| 1       | 1              |
| 2       | 2              |
+---------+----------------+
Explanation: 
The followers of 0 are {1}
The followers of 1 are {0}
The followers of 2 are {0,1}
```
