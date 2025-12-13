부품(part), 주문(lineorder), 고객(customer) 테이블을 조인하여 고객별 부품별 판매 총수량과 매출 합계를 구하세요.

정답:
SELECT 
  c.c_name,
  p.p_name,
  sum(l.lo_quantity) as total_qty,
  sum(l.lo_extendedprice) as total_revenue
FROM lineorder l
JOIN customer c ON l.lo_custkey = c.c_custkey
JOIN part p ON l.lo_partkey = p.p_partkey
GROUP BY c.c_name, p.p_name;


풀이:

1단계 
- 최종 SELECT에서 집계 대상 파악
- 판매총'수량', '매출' 합계 -> lo_quantity, lo_extendedprice

(mythink) 총매출이 애매한데, lo_extendedprice가 뭘 의미하는지 모르겠음.
  revenue는 수익마진의 의미라서 아닌거 같고, 매출이라 가격을 기반으로 수량과 곱해서 하는거 아닌지?
 아마도 extendedprice가 수량x가격인거 같다.

2단계 
- 집계대상이 lineorder 테이블에서 발생 -> 팩트테이블
- 조인이 필요한 테이블 파악 -> customer(c_custkey), part(p_partkey)
- 조인해서 필요한 컬럼이 뭔지 파악 -> c_custkey, c_name, p_partkey, p_name

3단계
- GROUP BY 기준 - c_custkey로 먼저 , p_partkey로 진행

4단계
- 성능 검토

5단계 
- 쿼리 작성
- 실행순서대로 작성 
  - FROM - JOIN - GROUPBY - SELECT - ORDERBY
