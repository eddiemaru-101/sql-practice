> 피타고라스로 풀면되는줄 알았는데  아니네..
> 피타고라스는 직각삼각형의 성질이다. 그냥 삼각형을 만들수 있는지 여부는 다르다.
> 참고로 그냥 제곱의 표현은 x*x 또는 POW(x,2)로 표현하면 됨.


```
세 변의 길이 중 가장 긴 변이 나머지 두 변의 합보다 작아야 함

-- 세 가지 조건을 모두 확인해야 함
x + y > z  -- x와 y의 합이 z보다 커야
AND
y + z > x  -- y와 z의 합이 x보다 커야  
AND
x + z > y  -- x와 z의 합이 y보다 커야
```

## 1단계
> CASE WHEN 적용하면 되겠네 했는데.. 문법에대한 이해가 부족했음


```
# Write your MySQL query statement below
SELECT
    x
    ,y
    ,z
    ,CASE 
        WHEN x + y >z THEN "Yes"
        OR
        WHEN y + z >x THEN "Yes"
        OR 
        WHEN z + x > y THEN "Yes"
        ELSE "No"
        END AS triangle

FROM Triangle;

```
- 각각의 WHEN 조건을 사용할 때
  - OR를 사용할 필요가 없음.
  - 독립적으로 적용되기 때문
```
SELECT 
    salary,
    CASE
        WHEN salary >= 10000 THEN 'High'
        WHEN salary >= 5000 THEN 'Medium'
        WHEN salary >= 2000 THEN 'Low'
        ELSE 'Very Low'
    END AS grade
FROM employees;
```
> 또 잘못알았네 ㅡㅡ  
> 3가지 모두 참이어야하는 조건이었음!!

- 적용하면
### 정답쿼리
```
SELECT
    x,
    y,
    z,
    CASE 
        WHEN (x + y > z) AND (y + z > x) AND (z + x > y)
        THEN "Yes"
        ELSE "No"
    END AS triangle
FROM Triangle;

<result>
| x  | y  | z  | triangle |
| -- | -- | -- | -------- |
| 13 | 15 | 30 | No       |
| 10 | 20 | 15 | Yes      |
```
