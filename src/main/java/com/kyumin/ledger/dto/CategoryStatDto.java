package com.kyumin.ledger.dto;

import java.math.BigDecimal;
import java.util.List;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class CategoryStatDto {
	private Integer categoryNum;
	private String categoryName;
	private String categoryEmoji;
	private Long amount;
	private BigDecimal ratio;
	private List<SubCategoryStatDto> children;
}