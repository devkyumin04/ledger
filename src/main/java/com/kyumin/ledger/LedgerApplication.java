package com.kyumin.ledger;

import java.util.TimeZone;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import jakarta.annotation.PostConstruct;

@SpringBootApplication
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
