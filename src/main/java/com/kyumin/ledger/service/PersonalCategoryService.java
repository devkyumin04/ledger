package com.kyumin.ledger.service;

import java.util.List;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import lombok.RequiredArgsConstructor;

import com.kyumin.ledger.domain.PersonalCategory;
import com.kyumin.ledger.dto.CategoryRequestDto;
import com.kyumin.ledger.dto.CategoryResponseDto;
import com.kyumin.ledger.mapper.PersonalCategoryMapper;

@Service
@RequiredArgsConstructor
public class PersonalCategoryService {

    private final PersonalCategoryMapper personalCategoryMapper;

    public CategoryResponseDto createCategory(Integer userNum, CategoryRequestDto requestDto) {
        // 1. requestDto의 값 + userNum으로 PersonalCategory 객체 만들기
    	PersonalCategory newPersonalCategory = new PersonalCategory();
    	newPersonalCategory.setUserNum(userNum);
    	newPersonalCategory.setParentCategoryNum(requestDto.getParentCategoryNum());
    	newPersonalCategory.setCategoryName(requestDto.getCategoryName());
    	newPersonalCategory.setCategoryEmoji(requestDto.getCategoryEmoji());
    	newPersonalCategory.setCategoryType(requestDto.getCategoryType());
    	newPersonalCategory.setIsDefaultYn("N");
    	newPersonalCategory.setUseYn("Y");
    	// 2. Mapper로 insert
    	personalCategoryMapper.insertCategory(newPersonalCategory);
        // 3. CategoryResponseDto로 변환해서 반환
    	return new CategoryResponseDto(
    		newPersonalCategory.getCategoryNum(),
    		newPersonalCategory.getCategoryName(),
    		newPersonalCategory.getCategoryEmoji(),
    		newPersonalCategory.getCategoryType(),
    		newPersonalCategory.getParentCategoryNum()
    	);
    }

    public List<CategoryResponseDto> getCategories(Integer userNum) {
        // 1. Mapper로 조회
    	List<PersonalCategory> categories = personalCategoryMapper.findByUserNum(userNum);
        // 2. List<PersonalCategory>를 List<CategoryResponseDto>로 변환해서 반환
    	return categories.stream()
		    .map(category -> new CategoryResponseDto(
		        category.getCategoryNum(),
		        category.getCategoryName(),
		        category.getCategoryEmoji(),
		        category.getCategoryType(),
		        category.getParentCategoryNum()
		    ))
		    .collect(Collectors.toList());
    }
}