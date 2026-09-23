package com.kyumin.ledger.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

// 새 비밀번호 규칙은 SignupRequestDto.password 와 같아야 한다
@Getter
@Setter
@NoArgsConstructor
public class PasswordChangeRequestDto {

	@NotBlank(message = "현재 비밀번호를 입력해주세요")
	private String currentPassword;

	@NotBlank(message = "새 비밀번호를 입력해주세요.")
	@Size(min = 8, max = 20, message = "비밀번호는 8자 이상 20자 이하로 입력해주세요.")
	@Pattern(regexp = "^(?=.*[a-zA-Z])(?=.*[0-9])(?=.*[^a-zA-Z0-9]).*$", message = "비밀번호는 영문, 숫자, 특수문자를 각각 1자 이상 포함해야 합니다.")
	private String newPassword;
}
