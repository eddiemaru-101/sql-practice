> 윽.. 이건 count가 아니라 그 값들의 합을 구해야 하구나..  
> 근데 첫번째 연도는 어떻게 구하지? MIN 함수 써야겠구나!  
> 대충 감을 잡음!

- 영어공부
```
  "Return all sales entries for that product in that year."

데이터베이스에서 Entry(Entries)는 '기록' 또는 '데이터 행(Row)'을 의미.

- 사전적 의미: 항목, 기입, 등록물
- 기술적 의미: 테이블(Table)에 저장된 개별적인 데이터 레코드(Record).
- 문장 내 역할: 해당 제품이 해당 연도에 판매된 모든 개별 건수(행)를 결과에 포함하라는 뜻입니다.
```
---
<br>  


## 1단계 - GROUP BY의 함정
> output 동일하게 나왔으나, 1차통과만 하고 최종통과에서 막힘..
> 알고보니 이건 GROUP BY 함정에 관한 문제였다
```
SELECT
    product_id
    , MIN(year) AS first_year
    , quantity
    , price
FROM Sales
GROUP BY product_id;

<result>
| product_id | first_year | quantity | price |
| ---------- | ---------- | -------- | ----- |
| 100        | 2008       | 10       | 5000  |
| 200        | 2011       | 15       | 9000  |
```
<br>  

### GROUP BY 기준컬럼이 아닌것은 집계함수 사용하지 않으면 랜덤값을 반환함
-- 현재 쿼리의 문제점
- GROUP BY에 없는 컬럼을 SELECT에 사용
  - product_id로만 GROUP BY 했는데 quantity, price를 SELECT에 넣음
  - MySQL은 ANY_VALUE()로 임의의 값을 반환함 (2008년 데이터가 아닐 수도 있음)
  - 표준 SQL에서는 에러 발생

- 의도와 실제 결과의 불일치
  - MIN(year)는 2008을 찾지만
  - quantity, price는 2008년 것이라는 보장이 없음
  - 2009년 데이터가 나올 수도 있음

- 그러니까 GROUP BY 기준 컬럼이 아닌 것은 집계함수를 사용해야하는데  
- 집계함수를 사용하지 않으면 그냥 랜덤값을 반환한다는 얘기.  
- MIN(year)에서 그 행 기준으로 다른 컬럼 값을 반환할거란 착각을 한 것임!  
- MIN(year)는 그 컬럼만 그렇게 반환한다는 것임. price, quantity도 MIN(year)에 해당하는 레코드의 값을 출력하는게 아님.  

```
-- GROUP BY product_id 하면 이렇게 그룹이 생성됨

[Product 100 그룹]
+---------+------------+------+----------+-------+
| sale_id | product_id | year | quantity | price |
+---------+------------+------+----------+-------+ 
| 1       | 100        | 2008 | 10       | 5000  |
| 2       | 100        | 2009 | 12       | 5000  |
| 3       | 100        | 2010 | 8        | 6000  |
+---------+------------+------+----------+-------+

[Product 200 그룹]
+---------+------------+------+----------+-------+
| sale_id | product_id | year | quantity | price |
+---------+------------+------+----------+-------+ 
| 7       | 200        | 2011 | 15       | 9000  |
| 8       | 200        | 2012 | 20       | 9000  |
+---------+------------+------+----------+-------+

[Product 100 그룹 - 3개 row]
year: 2008, quantity: 10, price: 5000
year: 2009, quantity: 12, price: 5000
year: 2010, quantity: 8,  price: 6000

SELECT 요구사항:
- product_id: 100 (모든 row가 같음, OK)
- MIN(year): 2008 (명확한 규칙, OK)
- quantity: ??? (10? 12? 8? 어느 걸 선택?)
- price: ??? (5000? 6000? 어느 걸 선택?)


"MySQL은 에러를 안 내고 임의로 하나를 골라줘. 이게 함정이야."

-- 다른 실행 결과 (데이터 순서에 따라 달라짐)
+------------+------------+----------+-------+
| product_id | first_year | quantity | price |
+------------+------------+----------+-------+ 
| 100        | 2008       | 8        | 6000  | -- 2010년 quantity와 price!
| 200        | 2011       | 20       | 9000  | -- 2012년 quantity!
+------------+------------+----------+-------+
```
<br>  
<br>  

## 2단계 
> 결국, MIN(year)에 해당하는 것을 찾아서 필터링만하면 되니까  
> WHERE IN (서브쿼리로)로 하는 수 밖에..!

- 정답쿼리
```
-- 정답 쿼리
SELECT
    product_id
    , year AS first_year
    , quantity
    , price
FROM Sales
WHERE (product_id, year) IN (
    SELECT
    product_id
    , MIN(year)
FROM Sales
GROUP BY product_id
);

| product_id | first_year | quantity | price |
| ---------- | ---------- | -------- | ----- |
| 100        | 2008       | 10       | 5000  |
| 200        | 2011       | 15       | 9000  |
```

<br>  
<br>  
<br>  

# 1070. Product Sales Analysis III
```
Table: Sales

+-------------+-------+
| Column Name | Type  |
+-------------+-------+
| sale_id     | int   |
| product_id  | int   |
| year        | int   |
| quantity    | int   |
| price       | int   |
+-------------+-------+
(sale_id, year) is the primary key (combination of columns with unique values) of this table.
Each row records a sale of a product in a given year.
A product may have multiple sales entries in the same year.
Note that the per-unit price.

Write a solution to find all sales that occurred in the first year each product was sold.

For each product_id, identify the earliest year it appears in the Sales table.

Return all sales entries for that product in that year.

Return a table with the following columns: product_id, first_year, quantity, and price.
Return the result in any order.

 

Example 1:

Input: 
Sales table:
+---------+------------+------+----------+-------+
| sale_id | product_id | year | quantity | price |
+---------+------------+------+----------+-------+ 
| 1       | 100        | 2008 | 10       | 5000  |
| 2       | 100        | 2009 | 12       | 5000  |
| 7       | 200        | 2011 | 15       | 9000  |
+---------+------------+------+----------+-------+

Output: 
+------------+------------+----------+-------+
| product_id | first_year | quantity | price |
+------------+------------+----------+-------+ 
| 100        | 2008       | 10       | 5000  |
| 200        | 2011       | 15       | 9000  |
+------------+------------+----------+-------+
```
