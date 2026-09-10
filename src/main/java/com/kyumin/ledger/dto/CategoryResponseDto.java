package com.kyumin.ledger.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class CategoryResponseDto {
	private Integer categoryNum;
	private String categoryName;
	private String categoryEmoji;
	private String categoryType;
	private Integer parentCategoryNum;
}
