> 연속 3번 동일한 숫자 조건? 처음에 이걸 어떻게 접근하지? 생각했다.
> "자, 'consecutive(연속)'이라는 키워드를 봤을 때 엔지니어로서 가장 먼저 떠올려야 하는 건 뭘까?  
> 바로 id 값의 순서야. id가 autoincrement니까 1, 2, 3... 이렇게 순차적으로 증가하지.  
> 그럼 연속 3번이라는 건 id가 n, n+1, n+2인 세 행에서 num 값이 같아야 한다."

<br><br>


## 1단계 - 연속조건 → SELF JOIN
> "연속 3번 = 3개의 행이 필요 = 테이블을 3번 조인"


```
SELECT 
    l1.id
    ,l1.num
    ,l2.num
    ,l3.num
FROM Logs l1
INNER JOIN Logs l2
ON  l1.id = l2.id-1
INNER JOIN Logs l3
ON l2.id = l3.id-1;


| id | num | num | num |
| -- | --- | --- | --- |
| 1  | 1   | 1   | 1   |
| 2  | 1   | 1   | 2   |
| 3  | 1   | 2   | 1   |
| 4  | 2   | 1   | 2   |
| 5  | 1   | 2   | 2   |
```
<br><br>



## 2단계 - 조건절로 필터링

```
SELECT 
*
FROM Logs l1
INNER JOIN Logs l2
ON  l1.id = l2.id-1
INNER JOIN Logs l3
ON l2.id = l3.id-1
WHERE l1.num = l2.num = l3.num;

| id | num | id | num | id | num |
| -- | --- | -- | --- | -- | --- |
| 1  | 1   | 2  | 1   | 3  | 1   |
```

- 출력 정리하기
```
SELECT 
    l1.num AS ConsecutiveNums
FROM Logs l1
INNER JOIN Logs l2
ON  l1.id = l2.id-1
INNER JOIN Logs l3
ON l2.id = l3.id-1
WHERE l1.num = l2.num = l3.num;

| ConsecutiveNums |
| --------------- |
| 1               |
```
<br><br>


## 3단계 - 에러 
>  `WHERE l1.num = l2.num = l3.num` 이 조건 때문에 에러발생!
> 왜 문제가 되는지 알아보자
- 결론부터
```
-- AND조건으로 표기해야함 
<수정전>
WHERE l1.num = l2.num = l3.num;

<수정후>
WHERE l1.num = l2.num AND l2.num = l3.num
```

> 그전에 어떤 에러가 났는지 알아보자

```
<input>
| id | num |
| 1  | -1  |
| 2  | -1  |
| 3  | -1  |
```
```
-- 내 쿼리 결과 
| ConsecutiveNums |
| --------------- |

--<Expected>
| ConsecutiveNums |
| --------------- |
| -1              |
```
- 처리과정
  - '-1'이란 값과 boolean 값과 비교해서 연속된 '-1'의 값은 표현이 안된 것! 
```
(1) 'l1.num = l2.num'을 먼저 평가 → TRUE(1) 또는 FALSE(0) 반환  
(2) 그 결과(0 또는 1)를 'l3.num'과 비교  
(3) l3.num이 -1인데, TRUE/FALSE(1/0)와 비교하니까 항상 FALSE  
(4) 결과적으로 모든 행이 필터링됨"
```
<br><br>



## 4단계 - 풀테스트에서말고 발생하는 문제(DISTINC해야함)
> `WHERE l1.num = l2.num = l3.num` 때문에 발생할 수 있는 문제가 있다.

> **어떤문제?** 중복 결과가 발생하는 케이스
> **언제?** 연속 3번이상으로 숫자가 발생하는 경우 


```
+----+-----+
| id | num |
+----+-----+
| 1  | 7   |
| 2  | 7   |
| 3  | 7   |
| 4  | 7   |
| 5  | 7   |
| 6  | 3   |
+----+-----+
```

**Self-Join 결과:**
- l1(id=1), l2(id=2), l3(id=3) → num 모두 7 ✓
- l1(id=2), l2(id=3), l3(id=4) → num 모두 7 ✓
- l1(id=3), l2(id=4), l3(id=5) → num 모두 7 ✓

```
+-----------------+
| ConsecutiveNums |
+-----------------+
| 7               |
| 7               |
| 7               |  -- 3개 중복!
+-----------------+
```
**실무에선 잘못된 카운트로 산정되는 문제**
```
- 사용자가 연속 5일 로그인 → DISTINCT 안 쓰면 로그인 보너스를 3번 줄 뻔
- 센서 값이 연속 10회 임계치 초과 → DISTINCT 안 쓰면 알림이 8번 발송
- 주식이 연속 7일 상승 → DISTINCT 안 쓰면 분석 리포트에 같은 종목이 5번 나옴"
```

**DISTINCT 쓰면**
```
<수정 전>
SELECT
 l2.num AS ConsecutiveNums  

<수정 후>
SELECT
 DISTINCT l2.num AS ConsecutiveNums  -- 필수!
```


### 최종 정답쿼리
```
SELECT 
    DISTINCT l2.num AS ConsecutiveNums
FROM Logs l1
INNER JOIN Logs l2
ON  l1.id = l2.id-1
INNER JOIN Logs l3
ON l2.id = l3.id-1
WHERE l1.num = l2.num AND l2.num = l3.num;


| ConsecutiveNums |
| --------------- |
| 1               |
```









<br><br><br>

---
# 180. Consecutive Numbers
```
Table: Logs

+-------------+---------+
| Column Name | Type    |
+-------------+---------+
| id          | int     |
| num         | varchar |
+-------------+---------+
In SQL, id is the primary key for this table.
id is an autoincrement column starting from 1.
 

Find all numbers that appear at least three times consecutively.

Return the result table in any order.

The result format is in the following example.

 

Example 1:

Input: 
Logs table:
+----+-----+
| id | num |
+----+-----+
| 1  | 1   |
| 2  | 1   |
| 3  | 1   |
| 4  | 2   |
| 5  | 1   |
| 6  | 2   |
| 7  | 2   |
+----+-----+
Output: 
+-----------------+
| ConsecutiveNums |
+-----------------+
| 1               |
+-----------------+
Explanation: 1 is the only number that appears consecutively for at least three times.
```
