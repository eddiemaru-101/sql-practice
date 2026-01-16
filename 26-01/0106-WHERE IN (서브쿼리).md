> 문제이해하는데 좀 오래 걸렸다.  
> 첫 로그인후 바로 다음날 로그인한 비율을 구하는 문제다.  
> 영어 공부 잠깐 한걸 언급하자면,  

**"바로 다음날" 영어표현:**

```
(1) the fraction of players that logged in again on the day after the day they first logged in,
- 'the day after' = 특정한 그 하나의 날 (단수)
- 'days after' (복수) 였다면 → 여러 날 포함
- 'the day after' (단수 + the) → 딱 그 다음 하나의 날만

(2)the number of players who logged in on the day immediately following their initial login,
- 'immediately' = 바로, 즉시
- 'later' 였다면 → 나중에 (언젠가)
- 'eventually' 였다면 → 결국에는
- 'immediately' → 바로 그 순간, 중간 없이
```
## 1단계 - 첫 로그인만 뽑기
> 이것도 이전 문제와 유사하게 서브쿼리, 셀프조인으로 풀어야 한다는 감이 왔다.
> 첫 로그인한 날짜, 그 다음날 로그인 했는지 여부를 조인해야한다.
> 근데 그걸 한번에 쿼리를 어떻게 작성해야할지 감이 잡히진 않았다.
- 플레이어별 첫 로그인한 기록만 필터링하기!
```
SELECT
    player_id
    ,MIN(event_date)
FROM Activity
GROUP BY player_id;

<result>
| player_id | MIN(event_date) |
| --------- | --------------- |
| 1         | 2016-03-01      |
| 2         | 2017-06-25      |
| 3         | 2016-03-02      |
```

## 2단계 - 바로 다음날 재로그인 날짜 산출
> 지난 문제와 동일하게 where ~ in으로 풀어보자  
> 처음 로그인날짜 필터링 했고, 여기에 1일 더해서, 현재 테이블에 그 레코드가 있는지 확인하면 될 듯!  

> 근데 날짜 1일 더하는거 또 까묵까묵!  
### 날짜 연산함수 : DATE_ADD함수
```
-- 일반 형태
DATE_ADD(날짜컬럼, INTERVAL 숫자 단위)

-- 간단한 예시
DATE_ADD('2024-01-15', INTERVAL 1 DAY)
-- 결과: '2024-01-16'

DATE_ADD('2024-01-15', INTERVAL 7 DAY)
-- 결과: '2024-01-22'

DATE_ADD('2024-01-15', INTERVAL 1 MONTH)
-- 결과: '2024-02-15'
```

```
SELECT
    DATE_ADD(MIN(event_date), interval 1 DAY)
FROM Activity
GROUP BY player_id;

<reult>
| DATE_ADD(MIN(event_date), interval 1 DAY) |
| ----------------------------------------- |
| 2016-03-02                                |
| 2017-06-26                                |
| 2016-03-03                                |
```

## 3단계 - 서브쿼리로 적용하기
> 서브쿼리로 만들면서 문법 에러 났다. 리마인드하고 기억하자

- 문법실수한 거
 - 서브쿼리에는 ; 를 붙이지 않는다.
 - WHERE IN에서 조건 컬럼이 두가지면 (A,B) 소괄호를 사용한다.
```
-- 오답 쿼리
SELECT *
FROM Activity
WHERE player_id, event_date IN
(SELECT
    player_id
    ,DATE_ADD(MIN(event_date), interval 1 DAY)
FROM Activity
GROUP BY player_id;);


-- 수정된 쿼리
SELECT *
FROM Activity
WHERE (player_id, event_date) IN
(SELECT
    player_id
    ,DATE_ADD(MIN(event_date), interval 1 DAY)
FROM Activity
GROUP BY player_id);

<result>

| player_id | device_id | event_date | games_played |
| --------- | --------- | ---------- | ------------ |
| 1         | 2         | 2016-03-02 | 6            |

```


## 4단계 - 출력부분 마무리
> 헉.. 그런데 fraction이니까 전체 플레이어 id수를 구해야 하는데 막혔다..  
> 테이블엔 1개 플레이어 기록밖에 없는데..  
> 그렇다. 그건 또 서브쿼리로 해결해야함..  

- **정답 쿼리** 
```
-- 정답 쿼리 
SELECT 
    ROUND(COUNT(DISTINCT player_id)/ (SELECT COUNT(DISTINCT player_id) FROM Activity),2) AS fraction 
FROM Activity
WHERE (player_id, event_date) IN
(SELECT
    player_id
    ,DATE_ADD(MIN(event_date), interval 1 DAY)
FROM Activity
GROUP BY player_id);

<result>
| fraction |
| -------- |
| 0.33     |
```

# 550. Game Play Analysis IV
```
Table: Activity

+--------------+---------+
| Column Name  | Type    |
+--------------+---------+
| player_id    | int     |
| device_id    | int     |
| event_date   | date    |
| games_played | int     |
+--------------+---------+
(player_id, event_date) is the primary key (combination of columns with unique values) of this table.
This table shows the activity of players of some games.
Each row is a record of a player who logged in and played a number of games (possibly 0)
before logging out on someday using some device.  

Write a solution to report the fraction of players that logged in again on the day after the day they first logged in,
rounded to 2 decimal places.   
In other words, you need to determine the number of players who logged in on the day
immediately following their initial login, and divide it by the number of total players.  

The result format is in the following example.  

 

Example 1:

Input: 
Activity table:
+-----------+-----------+------------+--------------+
| player_id | device_id | event_date | games_played |
+-----------+-----------+------------+--------------+
| 1         | 2         | 2016-03-01 | 5            |
| 1         | 2         | 2016-03-02 | 6            |
| 2         | 3         | 2017-06-25 | 1            |
| 3         | 1         | 2016-03-02 | 0            |
| 3         | 4         | 2018-07-03 | 5            |
+-----------+-----------+------------+--------------+
Output: 
+-----------+
| fraction  |
+-----------+
| 0.33      |
+-----------+
Explanation: 
Only the player with id 1 logged back in after the first day he had logged in so the answer is 1/3 = 0.33
```
