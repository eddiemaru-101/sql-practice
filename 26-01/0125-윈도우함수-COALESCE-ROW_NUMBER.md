> 일단 16일 이전의 최신날짜 찾는거까지 성공했다.  
> 하지만 서브쿼리로 하기엔 product_id별로 필터링한 날짜를 적용해야하는 방법을 몰라서 막혔다.  

<br><br> 

## 1단계 - 16일(포함) 이전중 최신날짜 필터링

```
SELECT
 product_id 
 ,MAX(change_date)
FROM Products
WHERE change_date <= '2019-08-16'
GROUP BY product_id;

| product_id | MAX(change_date) |
| ---------- | ---------------- |
| 1          | 2019-08-16       |
| 2          | 2019-08-14       |
```
<br>





> 음.. change_date 필드가 DATE타입인데 str으로 입력하면 형변환 일어나서 성능이 느려지지 않나?  
> 결론은 MySQL이 알아서 변환해서 한다 !




```
+---------------+---------+
| Column Name   | Type    |
+---------------+---------+
| product_id    | int     |
| new_price     | int     |
| change_date   | date    |
+---------------+---------+
```
```
WHERE change_date <= '2019-08-16'     -- 성능 동일
WHERE change_date <= DATE('2019-08-16')  -- 성능 동일


-- 쿼리 파싱 단계:
WHERE change_date <= '2019-08-16'
         ↓
WHERE change_date <= DATE('2019-08-16')  -- 내부적으로 변환
         ↓
WHERE change_date <= [18113]  -- 내부 DATE 표현
```



- ❌ 이건 진짜 성능 문제!
```
WHERE DATE(change_date) <= '2019-08-16'
```
- 왜? change_date 컬럼에 함수를 씌우면:
  - 인덱스를 못 써 (Function-based index 없으면)
  - 각 행마다 DATE() 함수 실행
  - 테이블 풀스캔 강제
<br><br><br>  



## 2단계 - join, where절 적용
> 자 필터링했으면 원본 테이블과 비교해야지! 
> 세가지 방법을 배웠다

```
1. WHERE IN
2. SELF JOIN
3. CTE(with문)


-- CTE
WITH ... 
-- 성능: 최신 MySQL에서는 최적화됨

-- 서브쿼리 JOIN  
INNER JOIN (SELECT ...) sub
-- 성능: CTE와 거의 동일 (MySQL 8.0+)

-- WHERE IN
WHERE (col1, col2) IN (SELECT ...)
-- 성능: 튜플 비교는 최적화가 덜 될 수 있음
```
- 일단 나는 CTE에 익숙해지기 위해 CTE를 사용했다
```
WITH last_price AS (SELECT
 product_id 
 ,MAX(change_date) AS latest_date
FROM Products
WHERE change_date <= '2019-08-16'
GROUP BY product_id)
SELECT
    p.product_id
    ,p.new_price  AS price
FROM Products p
JOIN last_price l
ON p.product_id =l.product_id 
AND p.change_date = l.latest_date;

| product_id | price |
| ---------- | ----- |
| 2          | 50    |
| 1          | 35    |
```
- 다음 문제는 `product_id=3`인 경우 10을 넣어줘야 한다.
<br><br> 

## 3단계 - `product_id=3`인 경우 넣기(UNION)
> CTE 테이블에 WHERE NOT IN 조건을 넣어서 사용한다.
> 그걸 UNION으로 묶는다 

```
-- 위의 쿼리 결과

UNION

SELECT DISTINCT
    product_id,
    10 AS price
FROM Products
WHERE product_id NOT IN (
    SELECT product_id 
    FROM Products 
    WHERE change_date <= '2019-08-16'
);
```

- 오류 1: CTE 스코프 문제
  - **"CTE는 바로 다음 SELECT문에서만 사용 가능해. UNION 이후는 별도 SELECT라서 last_price를 못 봐."**
```
WITH last_price AS (SELECT
 product_id 
 ,MAX(change_date) AS latest_date
FROM Products
WHERE change_date <= '2019-08-16'
GROUP BY product_id)
SELECT
    p.product_id
    ,p.new_price  AS price
FROM Products p
JOIN last_price l
ON p.product_id =l.product_id 
AND p.change_date = l.latest_date

UNION

SELECT 
    product_id 
    , 10 AS price
FROM Products
WHERE (product_id ,change_date) NOT IN (last_price);  -- ❌ last_price를 못 찾음
                                                      -- ❌ last_price는 테이블이지, 서브쿼리가 아니야
```
<br><br> 

## 4단계 - 정답쿼리
- 정답쿼리
- CTE 중복사용

```
-- CTE 중복사용 적용
-- 정답쿼리

WITH last_price AS (SELECT
 product_id 
 ,MAX(change_date) AS latest_date
FROM Products
WHERE change_date <= '2019-08-16'
GROUP BY product_id)
SELECT
    p.product_id
    ,p.new_price  AS price
FROM Products p
JOIN last_price l
ON p.product_id =l.product_id 
AND p.change_date = l.latest_date

UNION

SELECT 
    product_id 
    , 10 AS price
FROM Products
WHERE product_id NOT IN (
    SELECT product_id FROM last_price 
);

| product_id | price |
| ---------- | ----- |
| 2          | 50    |
| 1          | 35    |
| 3          | 10    |
```
<br><br> 

## 5단계 - Window Function으로 풀기기
> Window Function 종류 중 하나가 ROW_NUMBER()이다

### ROW_NUMBER() 배경과 설명
> "옛날에는 '그룹별 최신 1개'를 찾는 게 진짜 복잡했어."
- 배경: 왜 Window Function이 생겼나?
**옛날 방식 (Window Function 없을 때)**
```
-- product_id별 최신 가격 찾기
-- 서브쿼리 + JOIN 필요
SELECT p1.product_id, p1.new_price
FROM Products p1
INNER JOIN (
    SELECT product_id, MAX(change_date) AS max_date
    FROM Products
    GROUP BY product_id
) p2
ON p1.product_id = p2.product_id 
AND p1.change_date = p2.max_date;
```
- 한계
```
-- 최신 3개는? 어떻게?
-- MAX로는 불가능
-- 복잡한 서브쿼리 여러 개 필요
```
<br> 

### ROW_NUMBER() 개념
```
| product_id | new_price | change_date |
| 1          | 20        | 2019-08-14  |
| 1          | 30        | 2019-08-15  |
| 1          | 35        | 2019-08-16  |
| 2          | 50        | 2019-08-14  |
| 2          | 65        | 2019-08-17  |
```
```
SELECT 
    product_id,
    new_price,
    change_date,
    ROW_NUMBER() OVER (
        PARTITION BY product_id 
        ORDER BY change_date DESC
    ) AS rn
FROM Products;

-- rn 컬럼이 추가
| product_id | new_price | change_date | rn |
| 1          | 35        | 2019-08-16  | 1  |
| 1          | 30        | 2019-08-15  | 2  |
| 1          | 20        | 2019-08-14  | 3  |
| 2          | 65        | 2019-08-17  | 1  |
| 2          | 50        | 2019-08-14  | 2  |
```
- 작동과정
```
(1) `PARTITION BY product_id`: 제품별로 그룹을 나눔
(2) 'ORDER BY change_date DESC' : 각 그룹 내에서 날짜 최신순으로 정렬
(3) 'ROW_NUMBER()' : "정렬된 순서대로 1, 2, 3... 번호 부여"

| product_id | change_date | rn |
| 1          | 2019-08-16  | 1  | ← 1번 그룹에서 1등
| 1          | 2019-08-15  | 2  | ← 1번 그룹에서 2등
| 1          | 2019-08-14  | 3  | ← 1번 그룹에서 3등
| 2          | 2019-08-17  | 1  | ← 2번 그룹에서 1등
| 2          | 2019-08-14  | 2  | ← 2번 그룹에서 2등
```

### 문제에 적용하면,
```
SELECT 
    product_id
    ,new_price
    ,change_date
    ,ROW_NUMBER() OVER (
        PARTITION BY product_id 
        ORDER BY change_date DESC
    ) AS rn
FROM Products;

| product_id | new_price | change_date | rn |
| ---------- | --------- | ----------- | -- |
| 1          | 35        | 2019-08-16  | 1  |
| 1          | 30        | 2019-08-15  | 2  |
| 1          | 20        | 2019-08-14  | 3  |
| 2          | 65        | 2019-08-17  | 1  |
| 2          | 50        | 2019-08-14  | 2  |
| 3          | 20        | 2019-08-18  | 1  |
```

### 다른 Window Function 종류  
- Window Function 종류
 - "Window Function은 여러 개가 있어. ROW_NUMBER()는 그중 하나."
```
Window Function
├── 순위 함수
│   ├── ROW_NUMBER()  ← 너가 쓴 것
│   ├── RANK()
│   └── DENSE_RANK()
├── 집계 함수
│   ├── SUM()
│   ├── AVG()
│   └── COUNT()
└── 값 접근 함수
    ├── LAG()
    ├── LEAD()
    └── FIRST_VALUE()
```
<br><br>  

**(1)순위 함수** 
```
-- ROW_NUMBER(): 무조건 1, 2, 3, 4...
ROW_NUMBER() OVER (ORDER BY score DESC)

-- RANK(): 동점이면 같은 순위, 다음은 건너뜀
RANK() OVER (ORDER BY score DESC)

-- DENSE_RANK(): 동점이면 같은 순위, 다음은 이어서
DENSE_RANK() OVER (ORDER BY score DESC)


| 이름 | 점수 | ROW_NUMBER | RANK | DENSE_RANK |
| 철수 | 95   | 1          | 1    | 1          |
| 영희 | 90   | 2          | 2    | 2          |
| 민수 | 90   | 3          | 2    | 2          | ← 동점
| 지영 | 85   | 4          | 4    | 3          | ← 차이!
```
<br><br> 



**(2)집계 함수**
```
-- SUM: 누적 합계
SUM(amount) OVER (ORDER BY date)

-- AVG: 이동 평균
AVG(price) OVER (PARTITION BY product_id ORDER BY date)

-- COUNT: 누적 개수
COUNT(*) OVER (ORDER BY date)
```
<br><br> 


**(3)값 접근 함수** 
```
-- LAG: 이전 행 값
LAG(price) OVER (ORDER BY date)

-- LEAD: 다음 행 값  
LEAD(price) OVER (ORDER BY date)

-- FIRST_VALUE: 그룹 내 첫 값
FIRST_VALUE(price) OVER (PARTITION BY product_id ORDER BY date)
```
<br><br> 


> 컥,, 내가 GROUP BY에서 사용하고 싶었던 함수들이 다 있었네..  
> 아니! "GROUP BY랑은 안 섞어. Window Function은 GROUP BY 없이 쓰는 게 포인트야."    

- 예시

```
| product_id | sale_date  | amount |
| 1          | 2024-01-01 | 100    |
| 1          | 2024-01-02 | 150    |
| 1          | 2024-01-03 | 200    |
| 2          | 2024-01-01 | 80     |
| 2          | 2024-01-02 | 120    |
```
- 집계 함수 예시
```
1.SUM() - 누적 합계
- "각 제품별로 날짜 순서대로 누적 합계. 원본 행은 그대로!"
SELECT 
    product_id,
    sale_date,
    amount,
    SUM(amount) OVER (
        PARTITION BY product_id 
        ORDER BY sale_date
    ) AS running_total
FROM sales;

| product_id | sale_date  | amount | running_total |
| 1          | 2024-01-01 | 100    | 100           | ← 100
| 1          | 2024-01-02 | 150    | 250           | ← 100+150
| 1          | 2024-01-03 | 200    | 450           | ← 100+150+200
| 2          | 2024-01-01 | 80     | 80            | ← 80
| 2          | 2024-01-02 | 120    | 200           | ← 80+120


#-- GROUP BY (행이 줄어듦)
SELECT 
    product_id,
    SUM(amount) AS total
FROM sales
GROUP BY product_id;

| product_id | total |
| 1          | 450   | ← 3개 행이 1개로
| 2          | 200   | ← 2개 행이 1개로
```
<br> 

- 값 접근 함수 예시
```
1. LAG() - 이전 행 값
SELECT 
    product_id,
    sale_date,
    amount,
    LAG(amount) OVER (
        PARTITION BY product_id 
        ORDER BY sale_date
    ) AS prev_amount
FROM sales;

| product_id | sale_date  | amount | prev_amount |
| 1          | 2024-01-01 | 100    | NULL        | ← 이전 없음
| 1          | 2024-01-02 | 150    | 100         | ← 이전 행
| 1          | 2024-01-03 | 200    | 150         | ← 이전 행
| 2          | 2024-01-01 | 80     | NULL        |
| 2          | 2024-01-02 | 120    | 80          |


2. LEAD() - 다음 행 값
SELECT 
    product_id,
    sale_date,
    amount,
    LEAD(amount) OVER (
        PARTITION BY product_id 
        ORDER BY sale_date
    ) AS next_amount
FROM sales;

| product_id | sale_date  | amount | next_amount |
| 1          | 2024-01-01 | 100    | 150         | ← 다음 행
| 1          | 2024-01-02 | 150    | 200         | ← 다음 행
| 1          | 2024-01-03 | 200    | NULL        | ← 다음 없음
| 2          | 2024-01-01 | 80     | 120         |
| 2          | 2024-01-02 | 120    | NULL        |


3. 실무 활용: 전일 대비 증감
SELECT 
    product_id,
    sale_date,
    amount,
    LAG(amount) OVER (
        PARTITION BY product_id 
        ORDER BY sale_date
    ) AS prev_amount,
    amount - LAG(amount) OVER (
        PARTITION BY product_id 
        ORDER BY sale_date
    ) AS change
FROM sales;


| product_id | sale_date  | amount | prev_amount | change |
| 1          | 2024-01-01 | 100    | NULL        | NULL   |
| 1          | 2024-01-02 | 150    | 100         | +50    |
| 1          | 2024-01-03 | 200    | 150         | +50    |
| 2          | 2024-01-01 | 80     | NULL        | NULL   |
| 2          | 2024-01-02 | 120    | 80          | +40    |
```


## 6단계 - COALESCE 
> "COALESCE는 NULL 처리 함수야."  
> "왼쪽부터 확인해서 NULL이 아닌 첫 번째 값 반환"  

### COALESCE 개념 
```
COALESCE(값1, 값2, 값3, ...)
- 동작: "왼쪽부터 확인해서 NULL이 아닌 첫 번째 값 반환"


ex)
SELECT COALESCE(NULL, 10);
-- 결과: 10

SELECT COALESCE(20, 10);
-- 결과: 20

SELECT COALESCE(NULL, NULL, 30, 40);
-- 결과: 30
```
```
| product_id | price |
| 1          | 100   |
| 2          | NULL  |
| 3          | 200   |
| 4          | NULL  |
```
```
SELECT 
    product_id,
    price,
    COALESCE(price, 0) AS final_price
FROM products;

| product_id | price | final_price |
| 1          | 100   | 100         | ← 원본 값
| 2          | NULL  | 0           | ← NULL → 0
| 3          | 200   | 200         | ← 원본 값
| 4          | NULL  | 0           | ← NULL → 0
```


### 다른 NULL 처리 함수들


```
1. IFNULL (MySQL 전용)
IFNULL(price, 0)
-- COALESCE(price, 0)과 동일
-- 단, 인자 2개만 가능

IF (MySQL 전용)
IF(price IS NULL, 0, price)
-- 조건문 방식

CASE (표준 SQL)
CASE 
    WHEN price IS NULL THEN 0 
    ELSE price 
END
-- 가장 범용적
```
- 실무 활용 예시

```
1. 이름 표시 (닉네임 우선)
- "닉네임 있으면 닉네임, 없으면 username, 둘 다 없으면 'Anonymous'"
SELECT 
    user_id,
    COALESCE(nickname, username, 'Anonymous') AS display_name
FROM users;

2. 할인가 계산
- "세일 가격 있으면 세일 가격, 없으면 정상가"
SELECT 
    product_id,
    COALESCE(sale_price, regular_price) AS final_price
FROM products;

```
<br><br>

## 7단계 - WINDOW Function, COALESCE로 풀기

```
WITH ranked AS (
    SELECT
        product_id,
        new_price,
        ROW_NUMBER() OVER (
            PARTITION BY product_id 
            ORDER BY change_date DESC
        ) AS rn
    FROM Products
    WHERE change_date <= '2019-08-16'
)
SELECT 
    all_p.product_id,
    COALESCE(r.new_price, 10) AS price
FROM (SELECT DISTINCT product_id FROM Products) all_p
LEFT JOIN ranked r 
    ON all_p.product_id = r.product_id 
    AND r.rn = 1;


| product_id | price |
| 1          | 35    |
| 2          | 50    |
| 3          | 10    |
```
- 특징:
 - 한 번에 처리
 - Products 1번 스캔
 - 더 빠름 (대용량 데이터)

```
1. ROW_NUMBER()로 각 제품별 최신 가격에 번호 1 부여
   ↓
2. 모든 product_id 확보 (3번 포함)
   ↓
3. LEFT JOIN으로 매칭 (3번은 NULL)
   ↓
4. COALESCE로 NULL → 10 변환
   ↓
결과: 1,2,3번 모두 출력
```

### UNION 방식과 비교
```
-- 이력 있는 것
SELECT ... FROM Products p
JOIN (SELECT MAX...) ...

UNION

-- 이력 없는 것
SELECT ..., 10 FROM Products
WHERE product_id NOT IN (...)
```
- 특징:
 - 케이스 분리 (명확)
 - Products 2~3번 스캔













 
<br><br> <br><br> <br><br> <br><br> <br><br> <br><br> <br><br> <br><br> <br><br> <br><br> <br><br> <br><br> 
---
# 1164. Product Price at a Given Date

```
Table: Products

+---------------+---------+
| Column Name   | Type    |
+---------------+---------+
| product_id    | int     |
| new_price     | int     |
| change_date   | date    |
+---------------+---------+
(product_id, change_date) is the primary key (combination of columns with unique values) of this table.
Each row of this table indicates that the price of some product was changed to a new price at some date.
Initially, all products have price 10.

Write a solution to find the prices of all products on the date 2019-08-16.

Return the result table in any order.

The result format is in the following example.

 

Example 1:

Input: 
Products table:
+------------+-----------+-------------+
| product_id | new_price | change_date |
+------------+-----------+-------------+
| 1          | 20        | 2019-08-14  |
| 2          | 50        | 2019-08-14  |
| 1          | 30        | 2019-08-15  |
| 1          | 35        | 2019-08-16  |
| 2          | 65        | 2019-08-17  |
| 3          | 20        | 2019-08-18  |
+------------+-----------+-------------+
Output: 
+------------+-------+
| product_id | price |
+------------+-------+
| 2          | 50    |
| 1          | 35    |
| 3          | 10    |
+------------+-------+
```
