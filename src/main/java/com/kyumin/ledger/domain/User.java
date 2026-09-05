package com.kyumin.ledger.domain;

import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
public class User {

    private Integer userNum;
    private String userId;
    private String userPw;
    private String userNickname;
    private String userEmail;
    private String userPhone;
    private String userBirth;
    private String userStatus;
    private Integer loginFailCount;
    private LocalDateTime lockedUntil;
    private String bookOpenYn;
    private String signupIp;
    private LocalDateTime userCreatedAt;
    private LocalDateTime userLastLoginAt;
}