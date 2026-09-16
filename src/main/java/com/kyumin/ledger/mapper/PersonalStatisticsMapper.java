package com.kyumin.ledger.mapper;

import java.time.LocalDate;
import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.kyumin.ledger.dto.CategoryStatRowDto;

@Mapper
public interface PersonalStatisticsMapper {

    /*
     * 개인 통계 매퍼
     *
     * 매퍼는 '꺼내오기'만 한다. 묶기(계층)·비율 계산·0 나누기 판정은 전부 서비스 몫.
     * 다만 SUM / GROUP BY 같은 집계는 DB 가 훨씬 빠르므로 SQL 에 맡긴다.
     *   → 구분선: DB 가 잘하는 계산은 SQL, 우리 서비스의 규칙이 들어가는 계산은 서비스
     *
     * 파라미터가 2개 이상이므로 @Param 필수 (CLAUDE.md 규칙)
     */

    /**
     * 기간 내 카테고리별 합계.
     *
     * 반환되는 한 줄 = 카테고리 하나의 합계 (소분류는 소분류대로, 대분류에 직접 달린 것은 그것대로).
     * 대분류로 묶는 것은 서비스가 parentCategoryNum 을 보고 한다.
     *
     * 날짜는 [startDate, endDate) — 시작일 포함, 종료일 미포함.
     * 9월 조회라면 2026-09-01 ~ 2026-10-01 을 넘긴다.
     */
    List<CategoryStatRowDto> findCategoryStats(@Param("userNum") Integer userNum,
                                               @Param("startDate") LocalDate startDate,
                                               @Param("endDate") LocalDate endDate);

    // TODO 월별 추이(최근 6개월)용 메서드는 MonthlyStatDto 를 만든 뒤에 추가한다.
    //      같은 기간 조건에 GROUP BY 만 '월 + 타입' 으로 바뀐 형태가 될 것.
}
