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
}