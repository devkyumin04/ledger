package com.kyumin.ledger.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtTokenProvider jwtTokenProvider;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        // 1. 헤더에서 토큰 꺼내기
    	String header = request.getHeader("Authorization");

    	String token = null;
    	if (header != null && header.startsWith("Bearer ")) {
    	    token = header.substring(7);   // "Bearer " 7글자를 잘라내고 순수 토큰만 남김
    	}
        // 2. 토큰이 있고, 유효하면
    	if (token != null && jwtTokenProvider.validateToken(token)) {
    	    Integer userNum = jwtTokenProvider.getUserNumFromToken(token);

    	    UsernamePasswordAuthenticationToken authentication =
    	            new UsernamePasswordAuthenticationToken(userNum, null, java.util.Collections.emptyList());

    	    SecurityContextHolder.getContext().setAuthentication(authentication);
    	}
        // 3. 필터 체인 계속 진행 (이건 항상 마지막에 실행)
        filterChain.doFilter(request, response);
    }
}