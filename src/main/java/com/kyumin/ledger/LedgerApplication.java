package com.kyumin.ledger;

import java.util.TimeZone;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.security.autoconfigure.UserDetailsServiceAutoConfiguration;

import jakarta.annotation.PostConstruct;

// 인증은 JWT 필터가 한다 — Spring 이 기본으로 만드는 메모리 사용자(user + 랜덤 비번)는 쓰지 않으므로 끈다.
// 켜 두면 기동 로그에 "Using generated security password" 가 운영에서도 찍힌다
@SpringBootApplication(exclude = UserDetailsServiceAutoConfiguration.class)
public class LedgerApplication {

	public static void main(String[] args) {
		SpringApplication.run(LedgerApplication.class, args);
	}
	
	// jvm 기본 타임존 고정, 플래그는 실행 환경마다 따로 걸어야 해서 코드에 둔다
	@PostConstruct
	void initTimeZone() {
		TimeZone.setDefault(TimeZone.getTimeZone("Asia/Seoul"));
	}

}
