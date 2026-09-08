package com.kyumin.ledger.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import lombok.RequiredArgsConstructor;

import com.kyumin.ledger.dto.LoginRequestDto;
import com.kyumin.ledger.dto.LoginResponseDto;
import com.kyumin.ledger.dto.SignupRequestDto;
import com.kyumin.ledger.dto.SignupResponseDto;
import com.kyumin.ledger.service.UserService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @PostMapping("/signup")
    public ResponseEntity<SignupResponseDto> signup(@Valid @RequestBody SignupRequestDto requestDto) {

        SignupResponseDto responseDto = userService.signup(requestDto);

        return ResponseEntity.status(HttpStatus.CREATED).body(responseDto);
    }
    
    @PostMapping("/login")
    public ResponseEntity<LoginResponseDto> login(@Valid @RequestBody LoginRequestDto requestDto) {

        LoginResponseDto responseDto = userService.login(requestDto);

        return ResponseEntity.status(HttpStatus.OK).body(responseDto);
    }
}