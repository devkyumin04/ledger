package com.kyumin.dotoree.dto;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class MonthlyStatRowDto {
	private String yearMonth;
	private Long totalIncome;
	private Long totalExpense;
}
