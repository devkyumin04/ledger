package com.kyumin.ledger.dto;

import java.time.LocalDate;

import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class PersonalTransactionResponseDto {
	private Integer transNum;
	private Integer version;
	private Long transAmount;
	private LocalDate transDate;
	private String transMemo;
	private String transType;
	
	private String categoryName;
	private String categoryEmoji;
	
	private Integer categoryNum;
}
