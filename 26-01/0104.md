> 일단 GROUP BY에서 막혔지
> date타입 컬럼에서 월기준으로만 GROUP BY하는거 몰라서 막힘

## 0단계 - 월별 GROUP BY에서 막힘
> 일단 처음에 아래 쿼리 작성했는데,,
> 필터링 걸었는데 -> state값 "approved"
> 최종 결과에  approved_count가 있는걸로 봐선 필터링 걸면 안될듯!

```
SELECT *
FROM Transactions
WHERE state = "approved"
GROUP BY country, state, DATE(trans_date,month);

| id  | country | state    | amount | trans_date |
| --- | ------- | -------- | ------ | ---------- |
| 121 | US      | approved | 1000   | 2018-12-18 |
| 123 | US      | approved | 2000   | 2019-01-01 |
| 124 | DE      | approved | 2000   | 2019-01-07 |
```
<br> 


## 1단계 - 월별 GROUP BY 적용
- Mysql에서 날짜(date)를 월단위로 그룹핑하는 방법:
- SELECT에서 출력 형태를 바꿔주는 것과 동일한 원리 -> GROUP BY할때 DATE표현식을 변환해주는 것
```
DATE_FORMAT(컬럼, '포맷문자열')
DATE_FORMAT(trans_date, '%Y-%m')
```
- 적용하면,
```
SELECT *
FROM Transactions
GROUP BY country, state, DATE_FORMAT(trans_date, '%y-%m');

<result>
| id  | country | state    | amount | trans_date |
| --- | ------- | -------- | ------ | ---------- |
| 121 | US      | approved | 1000   | 2018-12-18 |
| 122 | US      | declined | 2000   | 2018-12-19 |
| 123 | US      | approved | 2000   | 2019-01-01 |
| 124 | DE      | approved | 2000   | 2019-01-07 |
```
> 그냥 원본이랑 동일해서 티가 안나지만 적용 된거 같음..
> GROUP BY할때만 저렇게 적용하면 SELECT로 출력할때 변하는지 확인해보자!
> 안되네..

```
SELECT 
    trans_date
FROM Transactions
GROUP BY country, state, DATE_FORMAT(trans_date, '%Y-%m');

| trans_date |
| ---------- |
| 2018-12-18 |
| 2018-12-19 |
| 2019-01-01 |
| 2019-01-07 |
```
<br> 


## 2단계 - SELECT 다듬기 I
> CASE를 다시 써먹자!
> 중간에 쉬어서 잘 기억이 안나니까, 리마인드 해보자.

```
-- 일반 형태
CASE
  WHEN 조건 THEN 값1
  ELSE 값2
END

-- 이 문제에서
SUM(CASE WHEN rating < 3 THEN 1 ELSE 0 END)

동작 원리:
1. rating < 3이면 1, 아니면 0
2. SUM으로 1들의 개수를 셈
3. 결과 = rating < 3인 row 개수
```
- 일단 DATE_FORMAT에서 년도 4자리로 나타내려다가 실패
```
-- 잘못된 쿼리:
DATE_FORMAT(trans_date, '%yyyy-%m')

-- 4자리 연도로 표현하는 쿼리:
DATE_FORMAT(trans_date, '%Y-%m')

-- %Y = 4자리 년도 (2018, 2019)
-- %y = 2자리 년도 (18, 19)
-- %yyyy는 존재하지 않는 포맷
```
```
SELECT 
    DATE_FORMAT(trans_date, '%yyyy-%m') AS month
    ,country
    ,COUNT(trans_date) AS trans_count
    ,SUM(CASE WHEN state="approved" THEN 1 ELSE 0 END) AS approved_count
    ,SUM(amount) AS trans_total_amount
    ,CASE WHEN state="approved" THEN SUM(amount) ELSE 0  END AS approved_total_amount
FROM Transactions
GROUP BY country, state, DATE_FORMAT(trans_date, '%Y-%m');


| month    | country | trans_count | approved_count | trans_total_amount | approved_total_amount |
| -------- | ------- | ----------- | -------------- | ------------------ | --------------------- |
| 18yyy-12 | US      | 1           | 1              | 1000               | 1000                  |
| 18yyy-12 | US      | 1           | 0              | 2000               | 0                     |
| 19yyy-01 | US      | 1           | 1              | 2000               | 2000                  |
| 19yyy-01 | DE      | 1           | 1              | 2000               | 2000                  |

```


## 3단계 - SELECT 다듬기 II
> 멀다멀어..MEDIUM레벨인 이유가 있었어

**- 첫번째 수정사항**
  - GROUP BY에 state 제거
```
--현재 (틀림):
GROUP BY country, state, DATE_FORMAT(trans_date, '%Y-%m')

--수정:
GROUP BY country, DATE_FORMAT(trans_date, '%Y-%m')

--왜 :
- 지금은 (US, approved), (US, declined) 각각 따로 그룹이 됨
- 문제는 (US, 2018-12) 하나로 묶어서 그 안에서 approved 개수를 세라는 의미
```
<br>
 
**- 두번쨰 수정사항**
  - CASE 문 문법
```
수정 전: 
,CASE WHEN state="approved" THEN SUM(amount) ELSE 0 END AS approved_total_amount

수정:
,SUM(CASE WHEN state="approved" THEN amount ELSE 0 END) AS approved_total_amount

-- 집계 함수 안에 CASE가 들어가야 함
-- 각 행마다 조건 체크 → approved면 amount, 아니면 0 → 그걸 SUM
```
<br>


### 최종 정답쿼리
```
SELECT 
    DATE_FORMAT(trans_date, '%Y-%m') AS month
    ,country
    ,COUNT(trans_date) AS trans_count
    ,SUM(CASE WHEN state="approved" THEN 1 ELSE 0 END) AS approved_count
    ,SUM(amount) AS trans_total_amount
    ,SUM(CASE WHEN state="approved" THEN amount ELSE 0 END) AS approved_total_amount
FROM Transactions
GROUP BY country, DATE_FORMAT(trans_date, '%Y-%m');

<result>
| month   | country | trans_count | approved_count | trans_total_amount | approved_total_amount |
| ------- | ------- | ----------- | -------------- | ------------------ | --------------------- |
| 2018-12 | US      | 2           | 1              | 3000               | 1000                  |
| 2019-01 | US      | 1           | 1              | 2000               | 2000                  |
| 2019-01 | DE      | 1           | 1              | 2000               | 2000                  |
```
> 미세최적화
```
수정 전:
,SUM(CASE WHEN state="approved" THEN 1 ELSE 0 END) AS approved_count
,SUM(CASE WHEN state="approved" THEN amount ELSE 0 END) AS approved_total_amount

수정 후: 
,COUNT(CASE WHEN state="approved" THEN 1 END) AS approved_count
,SUM(CASE WHEN state="approved" THEN amount END) AS approved_total_amount
  
  
-- NULL은 자동으로 무시되니까 ELSE 0 생략 가능
-- 차이는 0.01% 수준, 가독성 차원에서 선택
```



<br>
<br>


# 1193. Monthly Transactions I
```
Table: Transactions

+---------------+---------+
| Column Name   | Type    |
+---------------+---------+
| id            | int     |
| country       | varchar |
| state         | enum    |
| amount        | int     |
| trans_date    | date    |
+---------------+---------+
id is the primary key of this table.
The table has information about incoming transactions.
The state column is an enum of type ["approved", "declined"].
 

Write an SQL query to find for each month and country, the number of transactions and their total amount, the number of approved transactions and their total amount.

Return the result table in any order.

The query result format is in the following example.

 

Example 1:

Input: 
Transactions table:
+------+---------+----------+--------+------------+
| id   | country | state    | amount | trans_date |
+------+---------+----------+--------+------------+
| 121  | US      | approved | 1000   | 2018-12-18 |
| 122  | US      | declined | 2000   | 2018-12-19 |
| 123  | US      | approved | 2000   | 2019-01-01 |
| 124  | DE      | approved | 2000   | 2019-01-07 |
+------+---------+----------+--------+------------+
Output: 
+----------+---------+-------------+----------------+--------------------+-----------------------+
| month    | country | trans_count | approved_count | trans_total_amount | approved_total_amount |
+----------+---------+-------------+----------------+--------------------+-----------------------+
| 2018-12  | US      | 2           | 1              | 3000               | 1000                  |
| 2019-01  | US      | 1           | 1              | 2000               | 2000                  |
| 2019-01  | DE      | 1           | 1              | 2000               | 2000                  |
+----------+---------+-------------+----------------+--------------------+-----------------------+
```
