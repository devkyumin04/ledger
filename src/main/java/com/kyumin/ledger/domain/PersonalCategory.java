package com.kyumin.ledger.domain;

import java.time.LocalDateTime;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class PersonalCategory {
	private Integer categoryNum;
	private Integer userNum;
	private Integer parentCategoryNum;
	private String categoryName;
	private String categoryEmoji;
	private String categoryType;
	private String isDefaultYn;
	private String useYn;
	private LocalDateTime createdAt;
}
