package com.kyumin.ledger.mapper;

import org.apache.ibatis.annotations.Mapper;
import com.kyumin.ledger.domain.User;

@Mapper
public interface UserMapper {

    // 이메일 중복 확인용
    User findByEmail(String email);

    // 회원가입
    void insertUser(User user);

}