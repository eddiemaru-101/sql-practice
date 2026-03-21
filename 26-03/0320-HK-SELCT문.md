> 다시 시작해보자!
> 조금 쉬운문제부터 워밍업해보자

# [HackerRANK]Revising the Select Query I
Query all columns for all American cities in the CITY table with populations larger than 100000. The CountryCode for America is USA.
The CITY table is described as follows:

<img width="365" height="300" alt="image" src="https://github.com/user-attachments/assets/28fac062-4252-4c4b-9568-35e6475a419c" />

- 초과/미만 영어표현
```
larger than (초과)
less than (미만)
```

# 1단계 
> 이정도는 이제 바로 풀기

- 정답쿼리
```
SELECT *
FROM CITY
WHERE COUNTRYCODE = 'USA'
AND POPULATION > 100000


3878 Scottsdale USA Arizona 202705 
3965 Corona USA California 124966 
3973 Concord USA California 121780 
3977 Cedar Rapids USA Iowa 120758 
3982 Coral Springs USA Florida 117549 
```
