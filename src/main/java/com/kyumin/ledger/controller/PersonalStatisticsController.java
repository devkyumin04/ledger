package com.kyumin.ledger.controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import lombok.RequiredArgsConstructor;

import com.kyumin.ledger.dto.CategoryStatDto;
import com.kyumin.ledger.dto.MonthlyStatDto;
import com.kyumin.ledger.service.PersonalStatisticsService;

@RestController
@RequestMapping("/api/statistics")
@RequiredArgsConstructor
public class PersonalStatisticsController {

	/*
	 * 임시 컨트롤러.
	 * 봉투 묶기 로직이 맞는지 눈으로 확인하려고 만든 것이다.
	 * 최종 API 는 GET /api/statistics?year=&month= 하나로 합친다
	 * (수입 목록, 6개월 추이, 소비율까지 한 응답에).
	 * 그때 이 /expense 는 지우거나 남겨둘지 판단할 것.
	 */

	private final PersonalStatisticsService personalStatisticsService;

	@GetMapping("/expense")
	public ResponseEntity<List<CategoryStatDto>> getExpenseStats(
			@AuthenticationPrincipal Integer userNum,
			@RequestParam int year,
			@RequestParam int month) {

		List<CategoryStatDto> responseDtoList =
				personalStatisticsService.getExpenseStats(userNum, year, month);

		return ResponseEntity.status(HttpStatus.OK).body(responseDtoList);
	}

	@GetMapping("/income")
	public ResponseEntity<List<CategoryStatDto>> getIncomeStats(
			@AuthenticationPrincipal Integer userNum,
			@RequestParam int year,
			@RequestParam int month) {

		List<CategoryStatDto> responseDtoList =
				personalStatisticsService.getIncomeStats(userNum, year, month);

		return ResponseEntity.status(HttpStatus.OK).body(responseDtoList);
	}

	@GetMapping("/monthly")
	public ResponseEntity<List<MonthlyStatDto>> getMonthlyStats(
			@AuthenticationPrincipal Integer userNum,
			@RequestParam int year,
			@RequestParam int month) {

		List<MonthlyStatDto> responseDtoList =
				personalStatisticsService.getMonthlyStats(userNum, year, month);

		return ResponseEntity.status(HttpStatus.OK).body(responseDtoList);
	}
}
