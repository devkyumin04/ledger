package com.kyumin.ledger.dto;

import java.math.BigDecimal;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class SubCategoryStatDto {
	private Integer categoryNum;
	private String categoryName;
	private String categoryEmoji;
	private Long amount;
	private BigDecimal ratio;
}
