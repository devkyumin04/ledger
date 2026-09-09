package com.kyumin.ledger.service;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import lombok.RequiredArgsConstructor;

import com.kyumin.ledger.mapper.UserMapper;
import com.kyumin.ledger.security.JwtTokenProvider;
import com.kyumin.ledger.dto.LoginRequestDto;
import com.kyumin.ledger.dto.LoginResponseDto;
import com.kyumin.ledger.dto.SignupRequestDto;
import com.kyumin.ledger.dto.SignupResponseDto;
import com.kyumin.ledger.exception.DuplicateEmailException;
import com.kyumin.ledger.exception.InvalidCredentialsException;
import com.kyumin.ledger.domain.User;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserMapper userMapper;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;

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
    
    public LoginResponseDto login(LoginRequestDto requestDto) {

        User loginUser = userMapper.findByEmail(requestDto.getEmail());
      	
        if(loginUser == null) {
        	throw new InvalidCredentialsException("이메일 또는 비밀번호가 일치하지 않습니다.");
        }

        boolean isPasswordMatch = passwordEncoder.matches(requestDto.getPassword(), loginUser.getUserPw());

        if (!isPasswordMatch) {
            throw new InvalidCredentialsException("이메일 또는 비밀번호가 일치하지 않습니다.");
        }

       String accessToken = jwtTokenProvider.createAccessToken(loginUser.getUserNum());
        
        return new LoginResponseDto(
            loginUser.getUserNum(),
            loginUser.getUserEmail(),
            loginUser.getUserNickname(),
            accessToken
        );
    }
    
    public LoginResponseDto getMyInfo(Integer userNum) {

        User user = userMapper.findByUserNum(userNum);

        if (user == null) {
            throw new InvalidCredentialsException("사용자를 찾을 수 없습니다.");
        }

        return new LoginResponseDto(
            user.getUserNum(),
            user.getUserEmail(),
            user.getUserNickname(),
            null
        );
    }

}