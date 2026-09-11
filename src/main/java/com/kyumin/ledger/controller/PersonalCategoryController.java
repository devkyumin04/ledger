package com.kyumin.ledger.controller;

import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

import com.kyumin.ledger.dto.CategoryRequestDto;
import com.kyumin.ledger.dto.CategoryResponseDto;
import com.kyumin.ledger.service.PersonalCategoryService;

@RestController
@RequestMapping("/api/categories")
@RequiredArgsConstructor
public class PersonalCategoryController {

	/*	
	 * 	~Mapping의 종류
	 * 	GET : 조회
	 * 	POST : 등록(생성)
	 *  PUT : 전체 수정
	 *  PATCH : 일부 수정
	 *  DELETE : 삭제
	 */
	
	/*
	 * Controller 자주 쓰는 애노테이션
	 * @RestController        : 이 클래스는 API 응답(JSON)을 반환하는 컨트롤러
	 * @RequestMapping("...")  : 클래스 전체의 공통 경로 접두어
	 * @GetMapping/@PostMapping 등 : 위 ~Mapping 표 참고, 메서드별 세부 경로+HTTP방식
	 * @PathVariable          : URL 경로에 담긴 값 꺼내기 (/api/categories/{categoryNum})
	 * @RequestBody           : 요청 본문(JSON)을 자바 객체로 변환
	 * @Valid                 : DTO에 붙은 검증 애노테이션(@NotBlank 등) 실제 작동시킴
	 * @AuthenticationPrincipal : 토큰에서 인증된 사용자 정보(userNum) 꺼내기
	 * @RequiredArgsConstructor : final 필드 생성자 자동 생성 (의존성 주입용)
	 */
	
	/*
	 * 자주 쓰는 HttpStatus
	 * 200 OK                  : 조회/수정 성공
	 * 201 CREATED             : 생성 성공
	 * 204 NO_CONTENT          : 성공했지만 돌려줄 내용 없음 (삭제 등)
	 * 400 BAD_REQUEST         : 요청 값 자체가 잘못됨 (Validation 실패)
	 * 401 UNAUTHORIZED        : 인증 안 됨 (로그인 필요)
	 * 403 FORBIDDEN           : 권한 없음
	 * 404 NOT_FOUND           : 요청한 대상이 존재하지 않음
	 * 409 CONFLICT            : 이미 존재하는 리소스와 충돌 (중복 등)
	 * 500 INTERNAL_SERVER_ERROR : 서버 자체의 예상치 못한 오류
	 */
    private final PersonalCategoryService personalCategoryService;

    @PostMapping
    public ResponseEntity<CategoryResponseDto> createCategory(
            @AuthenticationPrincipal Integer userNum,
            @Valid @RequestBody CategoryRequestDto requestDto) {
    	
    	CategoryResponseDto responseDto = personalCategoryService.createCategory(userNum, requestDto);
    	
    	return ResponseEntity.status(HttpStatus.CREATED).body(responseDto);
    	
    }

    @GetMapping
    public ResponseEntity<List<CategoryResponseDto>> getCategories(
            @AuthenticationPrincipal Integer userNum) {

    	List<CategoryResponseDto> responseDtoList = personalCategoryService.getCategories(userNum);
        
        return ResponseEntity.status(HttpStatus.OK).body(responseDtoList);
    }
    
    @PutMapping("/{categoryNum}")
    public ResponseEntity<CategoryResponseDto> updateCategory(
            @AuthenticationPrincipal Integer userNum,
            @PathVariable Integer categoryNum,
            @Valid @RequestBody CategoryRequestDto requestDto) {

        CategoryResponseDto responseDto = personalCategoryService.updateCategory(userNum, categoryNum, requestDto);
        return ResponseEntity.status(HttpStatus.OK).body(responseDto);
    }

    @DeleteMapping("/{categoryNum}")
    public ResponseEntity<Void> deleteCategory(
            @AuthenticationPrincipal Integer userNum,
            @PathVariable Integer categoryNum) {

        // deleteCategory 서비스 호출, 응답 body 없이 상태코드만
    	personalCategoryService.deleteCategory(userNum, categoryNum);
    	
    	return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
    }
    
}