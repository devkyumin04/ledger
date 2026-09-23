package com.kyumin.dotoree.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class MonthlyStatDto {
	private String yearMonth;
	private Long totalIncome;
	private Long totalExpense;
	private Long balance;
}