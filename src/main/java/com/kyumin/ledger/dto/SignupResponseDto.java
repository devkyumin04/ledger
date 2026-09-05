package com.kyumin.ledger.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class SignupResponseDto {
	
	private Integer userNum;
	private String email;
	private String nickname;
}
