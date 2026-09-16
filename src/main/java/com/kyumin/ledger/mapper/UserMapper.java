package com.kyumin.ledger.mapper;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import com.kyumin.ledger.domain.User;

@Mapper
public interface UserMapper {

    // 이메일 중복 확인용
    User findByEmail(@Param("email") String email);

    // 회원가입
    void insertUser(User user);
    
    User findByUserNum(@Param("userNum") Integer userNum);

    void updateLastLoginAt(@Param("userNum") Integer userNum);

}