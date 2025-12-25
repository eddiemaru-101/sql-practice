> 어떻게 풀지 감을 못잡음. 조인을 3번 해야하는건 알았지만  
> 3개 테이블 조인을 어떻게 해야할지 몰랐음  


## 1단계 - CROSS JOIN
- 학생,교과목의 모든 경우의수를 매핑필요
- 최종 테이블에서 시험응시 0회도 포함되어야하기 때문
```
SELECT *
FROM Students stu
CROSS JOIN Subjects s;

<Result>
| student_id | student_name | subject_name |
| ---------- | ------------ | ------------ |
| 1          | Alice        | Programming  |
| 1          | Alice        | Physics      |
| 1          | Alice        | Math         |
| 2          | Bob          | Programming  |
| 2          | Bob          | Physics      |
| 2          | Bob          | Math         |
| 13         | John         | Programming  |
| 13         | John         | Physics      |
| 13         | John         | Math         |
| 6          | Alex         | Programming  |
| 6          | Alex         | Physics      |
| 6          | Alex         | Math         |

<테이블 Examinations>
+------------+--------------+
| student_id | subject_name |
+------------+--------------+
| 1          | Math         |
| 1          | Physics      |
| 1          | Programming  |
| 2          | Programming  |
| 1          | Physics      |
| 1          | Math         |
| 13         | Math         |
| 13         | Programming  |
| 13         | Physics      |
| 2          | Math         |
| 1          | Math         |
+------------+--------------+
```



## 2단계 - 3개테이블조인(오답)
> ON조건절을 또 잘못 적음  
> stu.student_id = e.student_id 하나만 적으면 안됨  
> 항상 JOIN할떈 한 아이디를 기준으로 테이블 형태를 보고 결과 테이블을 예상해야함  
> 지금 조건은 student_id만 동일하면 안되고 subject_name까지 같은거만 매핑해서 옆에 조인해야함
- stu.student_id = e.student_id 하나만 적용했을때
  - Alice기준으로 1단계 CROSS JOIN결과(3) + Examinations(6) = 18개 record 생성해버림(잘못됨)
```
SELECT *
FROM Students stu
CROSS JOIN Subjects s
LEFT JOIN Examinations e
ON stu.student_id = e.student_id;


<Result>
| student_id | student_name | subject_name | student_id | subject_name |
| ---------- | ------------ | ------------ | ---------- | ------------ |
| 1          | Alice        | Programming  | 1          | Math         |
| 1          | Alice        | Programming  | 1          | Math         |
| 1          | Alice        | Programming  | 1          | Physics      |
| 1          | Alice        | Programming  | 1          | Programming  |
| 1          | Alice        | Programming  | 1          | Physics      |
| 1          | Alice        | Programming  | 1          | Math         |
| 1          | Alice        | Physics      | 1          | Math         |
| 1          | Alice        | Physics      | 1          | Math         |
| 1          | Alice        | Physics      | 1          | Physics      |
| 1          | Alice        | Physics      | 1          | Programming  |
| 1          | Alice        | Physics      | 1          | Physics      |
| 1          | Alice        | Physics      | 1          | Math         |
| 1          | Alice        | Math         | 1          | Math         |
| 1          | Alice        | Math         | 1          | Math         |
| 1          | Alice        | Math         | 1          | Physics      |
| 1          | Alice        | Math         | 1          | Programming  |
| 1          | Alice        | Math         | 1          | Physics      |
| 1          | Alice        | Math         | 1          | Math         |
| 2          | Bob          | Programming  | 2          | Math         |
| 2          | Bob          | Programming  | 2          | Programming  |
| 2          | Bob          | Physics      | 2          | Math         |
| 2          | Bob          | Physics      | 2          | Programming  |
| 2          | Bob          | Math         | 2          | Math         |
| 2          | Bob          | Math         | 2          | Programming  |
| 13         | John         | Programming  | 13         | Physics      |
| 13         | John         | Programming  | 13         | Programming  |
| 13         | John         | Programming  | 13         | Math         |
| 13         | John         | Physics      | 13         | Physics      |
| 13         | John         | Physics      | 13         | Programming  |
| 13         | John         | Physics      | 13         | Math         |
| 13         | John         | Math         | 13         | Physics      |
| 13         | John         | Math         | 13         | Programming  |
| 13         | John         | Math         | 13         | Math         |
| 6          | Alex         | Programming  | null       | null         |
| 6          | Alex         | Physics      | null       | null         |
| 6          | Alex         | Math         | null       | null         |
```

## 3단계 - 3개테이블조인 다시 
- ON절에 subject_name주니까 매핑이 자연스럽게 됨
-  student_id, subject_name 일치한것만 매핑되고
-  LEFT JOIN으로 시험안친 과목도 null로 표기됨
```
SELECT *
FROM Students stu
CROSS JOIN Subjects s
LEFT JOIN Examinations e
ON stu.student_id = e.student_id
AND s.subject_name = e.subject_name;

<result>
| student_id | student_name | subject_name | student_id | subject_name |
| ---------- | ------------ | ------------ | ---------- | ------------ |
| 1          | Alice        | Programming  | 1          | Programming  |
| 1          | Alice        | Physics      | 1          | Physics      |
| 1          | Alice        | Physics      | 1          | Physics      |
| 1          | Alice        | Math         | 1          | Math         |
| 1          | Alice        | Math         | 1          | Math         |
| 1          | Alice        | Math         | 1          | Math         |
| 2          | Bob          | Programming  | 2          | Programming  |
| 2          | Bob          | Physics      | null       | null         |
| 2          | Bob          | Math         | 2          | Math         |
| 13         | John         | Programming  | 13         | Programming  |
| 13         | John         | Physics      | 13         | Physics      |
| 13         | John         | Math         | 13         | Math         |
| 6          | Alex         | Programming  | null       | null         |
| 6          | Alex         | Physics      | null       | null         |
| 6          | Alex         | Math         | null       | null         |
```



## 4단계 - 집계
> 여기서는 null을 0으로 어떻게 표현할지 포인트!
> GROUP BY를 하고 집계함수를 쓰지 않으면 대표값만 보여주므로 결과가 예상처럼 나타나지 않음

| student_id | student_name | subject_name | student_id | subject_name |
| ---------- | ------------ | ------------ | ---------- | ------------ |
| 1          | Alice        | Programming  | 1          | Programming  |
| 1          | Alice        | Physics      | 1          | Physics      |
| 1          | Alice        | Physics      | 1          | Physics      |
| 1          | Alice        | Math         | 1          | Math         |
| 1          | Alice        | Math         | 1          | Math         |
| 1          | Alice        | Math         | 1          | Math         |
| 2          | Bob          | Programming  | 2          | Programming  |
| 2          | Bob          | Physics      | null       | null         |
| 2          | Bob          | Math         | 2          | Math         |
| 13         | John         | Programming  | 13         | Programming  |
| 13         | John         | Physics      | 13         | Physics      |
| 13         | John         | Math         | 13         | Math         |
| 6          | Alex         | Programming  | null       | null         |
| 6          | Alex         | Physics      | null       | null         |
| 6          | Alex         | Math         | null       | null         |

### GROUP BY 파헤치기
- 엔진은 GROUP BY s.student_id, s.student_name, sub.subject_name을 보고,
- 기준 컬럼들이 동일한 행들끼리 바구니(Group)에 담습니다.
  - Alice-Math 그룹: 행 번호 4, 5, 6번이 한 바구니에 담김
  - Bob-Physics 그룹: 행 번호 8번이 혼자 한 바구니에 담김
  - Alex-Math 그룹: 행 번호 15번이 혼자 한 바구니에 담김
- 하지만 결과는 대표값 1개만 보임

| student_id | student_name | subject_name | collected e.subject_name values        | rows_in_group |
|------------|--------------|--------------|-----------------------------------------|---------------|
| 1          | Alice        | Programming  | ['Programming']                         | 1             |
| 1          | Alice        | Physics      | ['Physics', 'Physics']                  | 2             |
| 1          | Alice        | Math         | ['Math', 'Math', 'Math']                | 3             |
| 2          | Bob          | Programming  | ['Programming']                         | 1             |
| 2          | Bob          | Physics      | [NULL]                                  | 1             |
| 2          | Bob          | Math         | ['Math']                                | 1             |
| 13         | John         | Programming  | ['Programming']                         | 1             |
| 13         | John         | Physics      | ['Physics']                             | 1             |
| 13         | John         | Math         | ['Math']                                | 1             |
| 6          | Alex         | Programming  | [NULL]                                  | 1             |
| 6          | Alex         | Physics      | [NULL]                                  | 1             |
| 6          | Alex         | Math         | [NULL]                                  | 1             |

- 실제 쿼리결과값
  - 실제 묶인 개수는 쿼리결과에 출력되지 않음
```
SELECT *
FROM Students stu
CROSS JOIN Subjects s
LEFT JOIN Examinations e
ON stu.student_id = e.student_id
AND s.subject_name = e.subject_name
GROUP BY stu.student_id, s.subject_name;

<result>
| student_id | student_name | subject_name | student_id | subject_name |
| ---------- | ------------ | ------------ | ---------- | ------------ |
| 1          | Alice        | Programming  | 1          | Programming  |
| 1          | Alice        | Physics      | 1          | Physics      |
| 1          | Alice        | Math         | 1          | Math         |
| 2          | Bob          | Programming  | 2          | Programming  |
| 2          | Bob          | Physics      | null       | null         |
| 2          | Bob          | Math         | 2          | Math         |
| 13         | John         | Programming  | 13         | Programming  |
| 13         | John         | Physics      | 13         | Physics      |
| 13         | John         | Math         | 13         | Math         |
| 6          | Alex         | Programming  | null       | null         |
| 6          | Alex         | Physics      | null       | null         |
| 6          | Alex         | Math         | null       | null         |
```

### GROUP BY + 집계함수 COUNT를 쓰면
> COUNT친 컬럼명 alias 지정 안하면 보기싫으니까 꼭 바꿔주자!

- COUNT 함수치면 GROUP BY만의 결과물에선 안보이던 바구니 개수가 표기된다.
- 근데 좀 이상한점이 눈에 띈다. -> null값이 1개로 카운트 되었다. 
```
SELECT stu.student_id
    , stu.student_name
    , s.subject_name
    , COUNT(s.subject_name)
FROM Students stu
CROSS JOIN Subjects s
LEFT JOIN Examinations e
ON stu.student_id = e.student_id
AND s.subject_name = e.subject_name
GROUP BY stu.student_id, s.subject_name;

<result>
| student_id | student_name | subject_name | COUNT(s.subject_name) |
| ---------- | ------------ | ------------ | --------------------- |
| 1          | Alice        | Programming  | 1                     |
| 1          | Alice        | Physics      | 2                     |
| 1          | Alice        | Math         | 3                     |
| 2          | Bob          | Programming  | 1                     |
| 2          | Bob          | Physics      | 1                     |
| 2          | Bob          | Math         | 1                     |
| 13         | John         | Programming  | 1                     |
| 13         | John         | Physics      | 1                     |
| 13         | John         | Math         | 1                     |
| 6          | Alex         | Programming  | 1                     |
| 6          | Alex         | Physics      | 1                     |
| 6          | Alex         | Math         | 1                     |
```

### COUNT 집계대상 설정 
> null값이 있을땐 COUNT 집계 대상 컬럼을 GROUP BY 결과 테이블을 잘 보고 판단해야 한다.

- 문제점파악하기
- COUNT(s.subject_name) -> 테이블의 왼쪽 subject_name이므로 null이 없다
- 즉, 드라이빙 테이블의 기준으로 COUNT해서 문제 발생
- COUNT(e.subject_name) -> null이 있는 컬럼
```
SELECT *
FROM Students stu
CROSS JOIN Subjects s
LEFT JOIN Examinations e
ON stu.student_id = e.student_id
AND s.subject_name = e.subject_name
GROUP BY stu.student_id, s.subject_name;

<result>
| student_id | student_name | subject_name | student_id | subject_name |
| ---------- | ------------ | ------------ | ---------- | ------------ |
| 1          | Alice        | Programming  | 1          | Programming  |
| 1          | Alice        | Physics      | 1          | Physics      |
| 1          | Alice        | Math         | 1          | Math         |
| 2          | Bob          | Programming  | 2          | Programming  |
| 2          | Bob          | Physics      | null       | null         |
| 2          | Bob          | Math         | 2          | Math         |
| 13         | John         | Programming  | 13         | Programming  |
| 13         | John         | Physics      | 13         | Physics      |
| 13         | John         | Math         | 13         | Math         |
| 6          | Alex         | Programming  | null       | null         |
| 6          | Alex         | Physics      | null       | null         |
| 6          | Alex         | Math         | null       | null         |
```

- 수정해서 쿼리 돌려보면
  - 이제 제대로 결과가 나옴
```
SELECT stu.student_id
    , stu.student_name
    , s.subject_name
    , COUNT(e.subject_name)
FROM Students stu
CROSS JOIN Subjects s
LEFT JOIN Examinations e
ON stu.student_id = e.student_id
AND s.subject_name = e.subject_name
GROUP BY stu.student_id, s.subject_name;

| student_id | student_name | subject_name | COUNT(e.subject_name) |
| ---------- | ------------ | ------------ | --------------------- |
| 1          | Alice        | Programming  | 1                     |
| 1          | Alice        | Physics      | 2                     |
| 1          | Alice        | Math         | 3                     |
| 2          | Bob          | Programming  | 1                     |
| 2          | Bob          | Physics      | 0                     |
| 2          | Bob          | Math         | 1                     |
| 13         | John         | Programming  | 1                     |
| 13         | John         | Physics      | 1                     |
| 13         | John         | Math         | 1                     |
| 6          | Alex         | Programming  | 0                     |
| 6          | Alex         | Physics      | 0                     |
| 6          | Alex         | Math         | 0                     |
```

## 5단계 정렬(ORDER BY)
- 정렬만 하면 끝~
```
SELECT stu.student_id
    , stu.student_name
    , s.subject_name
    , COUNT(e.subject_name) as attended_exams
FROM Students stu
CROSS JOIN Subjects s
LEFT JOIN Examinations e
ON stu.student_id = e.student_id
AND s.subject_name = e.subject_name
GROUP BY stu.student_id, s.subject_name
ORDER BY stu.student_id, s.subject_name;

<result>
| student_id | student_name | subject_name | attended_exams |
| ---------- | ------------ | ------------ | -------------- |
| 1          | Alice        | Math         | 3              |
| 1          | Alice        | Physics      | 2              |
| 1          | Alice        | Programming  | 1              |
| 2          | Bob          | Math         | 1              |
| 2          | Bob          | Physics      | 0              |
| 2          | Bob          | Programming  | 1              |
| 6          | Alex         | Math         | 0              |
| 6          | Alex         | Physics      | 0              |
| 6          | Alex         | Programming  | 0              |
| 13         | John         | Math         | 1              |
| 13         | John         | Physics      | 1              |
| 13         | John         | Programming  | 1              |

```


# [leet] 1280.Students and Examinations
```
Table: Students

+---------------+---------+
| Column Name   | Type    |
+---------------+---------+
| student_id    | int     |
| student_name  | varchar |
+---------------+---------+
student_id is the primary key (column with unique values) for this table.
Each row of this table contains the ID and the name of one student in the school.
 

Table: Subjects

+--------------+---------+
| Column Name  | Type    |
+--------------+---------+
| subject_name | varchar |
+--------------+---------+
subject_name is the primary key (column with unique values) for this table.
Each row of this table contains the name of one subject in the school.
 

Table: Examinations

+--------------+---------+
| Column Name  | Type    |
+--------------+---------+
| student_id   | int     |
| subject_name | varchar |
+--------------+---------+
There is no primary key (column with unique values) for this table. It may contain duplicates.
Each student from the Students table takes every course from the Subjects table.
Each row of this table indicates that a student with ID student_id attended the exam of subject_name.
 

Write a solution to find the number of times each student attended each exam.

Return the result table ordered by student_id and subject_name.

The result format is in the following example.

 

Example 1:

Input: 
Students table:
+------------+--------------+
| student_id | student_name |
+------------+--------------+
| 1          | Alice        |
| 2          | Bob          |
| 13         | John         |
| 6          | Alex         |
+------------+--------------+
Subjects table:
+--------------+
| subject_name |
+--------------+
| Math         |
| Physics      |
| Programming  |
+--------------+
Examinations table:
+------------+--------------+
| student_id | subject_name |
+------------+--------------+
| 1          | Math         |
| 1          | Physics      |
| 1          | Programming  |
| 2          | Programming  |
| 1          | Physics      |
| 1          | Math         |
| 13         | Math         |
| 13         | Programming  |
| 13         | Physics      |
| 2          | Math         |
| 1          | Math         |
+------------+--------------+
Output: 
+------------+--------------+--------------+----------------+
| student_id | student_name | subject_name | attended_exams |
+------------+--------------+--------------+----------------+
| 1          | Alice        | Math         | 3              |
| 1          | Alice        | Physics      | 2              |
| 1          | Alice        | Programming  | 1              |
| 2          | Bob          | Math         | 1              |
| 2          | Bob          | Physics      | 0              |
| 2          | Bob          | Programming  | 1              |
| 6          | Alex         | Math         | 0              |
| 6          | Alex         | Physics      | 0              |
| 6          | Alex         | Programming  | 0              |
| 13         | John         | Math         | 1              |
| 13         | John         | Physics      | 1              |
| 13         | John         | Programming  | 1              |
+------------+--------------+--------------+----------------+
Explanation: 
The result table should contain all students and all subjects.
Alice attended the Math exam 3 times, the Physics exam 2 times, and the Programming exam 1 time.
Bob attended the Math exam 1 time, the Programming exam 1 time, and did not attend the Physics exam.
Alex did not attend any exams.
John attended the Math exam 1 time, the Physics exam 1 time, and the Programming exam 1 time.
```
