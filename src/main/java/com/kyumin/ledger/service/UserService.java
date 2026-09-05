package com.kyumin.ledger.service;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import lombok.RequiredArgsConstructor;

import com.kyumin.ledger.mapper.UserMapper;
import com.kyumin.ledger.dto.SignupRequestDto;
import com.kyumin.ledger.dto.SignupResponseDto;
import com.kyumin.ledger.exception.DuplicateEmailException;
import com.kyumin.ledger.domain.User;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserMapper userMapper;
    private final PasswordEncoder passwordEncoder;

    public SignupResponseDto signup(SignupRequestDto requestDto) {

        User existingUser = userMapper.findByEmail(requestDto.getEmail());

        if (existingUser != null) {
            throw new DuplicateEmailException("이미 사용 중인 이메일입니다.");
        }

        String encodedPassword = passwordEncoder.encode(requestDto.getPassword());
        
        User newUser = new User();
        newUser.setUserEmail(requestDto.getEmail());
        newUser.setUserPw(encodedPassword);
        newUser.setUserNickname(requestDto.getNickname());
        newUser.setUserStatus("A");
        newUser.setBookOpenYn("N");
        newUser.setLoginFailCount(0);
        
        userMapper.insertUser(newUser);
        
        return new SignupResponseDto(
    	    newUser.getUserNum(),
    	    newUser.getUserEmail(),
    	    newUser.getUserNickname()
    	);
    }

}