package com.kyumin.dotoree;

import java.util.TimeZone;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.security.autoconfigure.UserDetailsServiceAutoConfiguration;
import org.springframework.scheduling.annotation.EnableScheduling;

import jakarta.annotation.PostConstruct;

// 인증은 JWT 필터가 한다 — Spring 이 기본으로 만드는 메모리 사용자(user + 랜덤 비번)는 쓰지 않으므로 끈다.
// 켜 두면 기동 로그에 "Using generated security password" 가 운영에서도 찍힌다
@SpringBootApplication(exclude = UserDetailsServiceAutoConfiguration.class)
@EnableScheduling // 탈퇴 계정 파기 (scheduler/AccountPurgeScheduler, ADR-052)
public class DotoreeApplication {

	public static void main(String[] args) {
		SpringApplication.run(DotoreeApplication.class, args);
	}
	
	// jvm 기본 타임존 고정, 플래그는 실행 환경마다 따로 걸어야 해서 코드에 둔다
	@PostConstruct
	void initTimeZone() {
		TimeZone.setDefault(TimeZone.getTimeZone("Asia/Seoul"));
	}

}
