package com.kyumin.ledger.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class CategoryRequestDto {
	
	private Integer parentCategoryNum;
	
	@NotBlank(message = "카테고리 이름을 입력하시오.") 
	private String categoryName;
	
	private String categoryEmoji;
	
	@NotBlank(message = "카테고리 타입을 지정하시오.")
	@Pattern(regexp="[IE]", message = "잘못된 카테고리 타입입니다!")
	private String categoryType;
}
