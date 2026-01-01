> 문제 이해가 조금 어려웠고, 일단 GROUP BY까지는 생각함



## 1단계 - GROUP BY
- 쿼리별로 묶고 연산처리해야하니까 일단 GROUP BY를 하자
```
SELECT *
FROM Queries q
GROUP BY q.query_name;

<result>
| query_name | result           | position | rating |
| ---------- | ---------------- | -------- | ------ |
| Dog        | Golden Retriever | 1        | 5      |
| Cat        | Shirazi          | 5        | 2      |
```
> 헐.. 그런데 테이블 하나일땐 alias 안붙여도 되네,,
> 컬럼명에 테이블 지정안해되 되네

```
SELECT *
FROM Queries
GROUP BY query_name;

| query_name | result           | position | rating |
| ---------- | ---------------- | -------- | ------ |
| Dog        | Golden Retriever | 1        | 5      |
| Cat        | Shirazi          | 5        | 2      |
```

## 2단계 - 연산할 내용정리하기
1. quality 
   = AVG(rating / position)
   = 각 row의 (rating/position) 합 / row 개수
   
2. poor_query_percentage
   = (rating < 3인 row 개수 / 전체 row 개수) * 100

- AVG() 함수
```
-- 일반 형태
AVG(column_name)

-- 계산식도 가능
AVG(rating / position)

동작 원리:
1. 각 row의 값을 계산 (rating/position)
2. 모든 값을 더함
3. row 개수로 나눔
```
- CASE WHEN (조건부 카운팅)
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

## 정답쿼리
```
SELECT 
    query_name,
    ROUND(AVG(rating / position), 2) as quality,
    ROUND(SUM(CASE WHEN rating < 3 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as poor_query_percentage
FROM Queries
GROUP BY query_name;

<result>
| query_name | quality | poor_query_percentage |
| ---------- | ------- | --------------------- |
| Dog        | 2.5     | 33.33                 |
| Cat        | 0.66    | 33.33                 |
```

<br>
<br>

# 1211. Queries Quality and Percentage
```
Table: Queries

+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| query_name  | varchar |
| result      | varchar |
| position    | int     |
| rating      | int     |
+-------------+---------+
This table may have duplicate rows.
This table contains information collected from some queries on a database.
The position column has a value from 1 to 500.
The rating column has a value from 1 to 5. Query with rating less than 3 is a poor query.
 

We define query quality as:

The average of the ratio between query rating and its position.

We also define poor query percentage as:

The percentage of all queries with rating less than 3.

Write a solution to find each query_name, the quality and poor_query_percentage.

Both quality and poor_query_percentage should be rounded to 2 decimal places.

Return the result table in any order.

The result format is in the following example.

 

Example 1:

Input: 
Queries table:
+------------+-------------------+----------+--------+
| query_name | result            | position | rating |
+------------+-------------------+----------+--------+
| Dog        | Golden Retriever  | 1        | 5      |
| Dog        | German Shepherd   | 2        | 5      |
| Dog        | Mule              | 200      | 1      |
| Cat        | Shirazi           | 5        | 2      |
| Cat        | Siamese           | 3        | 3      |
| Cat        | Sphynx            | 7        | 4      |
+------------+-------------------+----------+--------+
Output: 
+------------+---------+-----------------------+
| query_name | quality | poor_query_percentage |
+------------+---------+-----------------------+
| Dog        | 2.50    | 33.33                 |
| Cat        | 0.66    | 33.33                 |
+------------+---------+-----------------------+
Explanation: 
Dog queries quality is ((5 / 1) + (5 / 2) + (1 / 200)) / 3 = 2.50
Dog queries poor_ query_percentage is (1 / 3) * 100 = 33.33

Cat queries quality equals ((2 / 5) + (3 / 3) + (4 / 7)) / 3 = 0.66
Cat queries poor_ query_percentage is (1 / 3) * 100 = 33.33
```
