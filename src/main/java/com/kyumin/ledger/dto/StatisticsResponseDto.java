package com.kyumin.ledger.dto;

import java.math.BigDecimal;
import java.util.List;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class StatisticsResponseDto {
	private Long totalIncome;
	private Long totalExpense;
	private Long balance;
	private BigDecimal expenseRatio;
	private List<CategoryStatDto> expenseList;
	private List<CategoryStatDto> incomeList;
	private List<MonthlyStatDto> monthlyList;	
}
