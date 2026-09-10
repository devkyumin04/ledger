package com.kyumin.ledger.service;

import java.util.List;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import lombok.RequiredArgsConstructor;

import com.kyumin.ledger.domain.PersonalCategory;
import com.kyumin.ledger.dto.CategoryRequestDto;
import com.kyumin.ledger.dto.CategoryResponseDto;
import com.kyumin.ledger.exception.CategoryNotFoundException;
import com.kyumin.ledger.exception.InvalidCategoryAccessException;
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
    
    public CategoryResponseDto updateCategory(Integer userNum, Integer categoryNum, CategoryRequestDto requestDto) {
    	
        PersonalCategory category = personalCategoryMapper.findByCategoryNum(categoryNum);

        if (category == null) {
            throw new CategoryNotFoundException("존재하지 않는 카테고리입니다!");
        }

        if (!category.getUserNum().equals(userNum)) {
            throw new InvalidCategoryAccessException("본인의 카테고리만 수정할 수 있습니다!");
        }

        // 값 채우기 (requestDto의 값으로 category 객체 업데이트)
        category.setCategoryName(requestDto.getCategoryName());
        category.setCategoryEmoji(requestDto.getCategoryEmoji());
        category.setParentCategoryNum(requestDto.getParentCategoryNum());
        
        // Mapper로 update 호출
        personalCategoryMapper.updateCategory(category);
        // ResponseDto로 변환해서 반환
        return new CategoryResponseDto(
        	category.getCategoryNum(),
        	category.getCategoryName(),
        	category.getCategoryEmoji(),
        	category.getCategoryType(),
        	category.getParentCategoryNum()
        );
    }
    
    public void deleteCategory(Integer userNum, Integer categoryNum) {

        PersonalCategory category = personalCategoryMapper.findByCategoryNum(categoryNum);

        if (category == null) {
            throw new CategoryNotFoundException("존재하지 않는 카테고리입니다!");
        }

        if (!category.getUserNum().equals(userNum)) {
            throw new InvalidCategoryAccessException("본인의 카테고리만 수정할 수 있습니다!");
        }

        // '미분류' 카테고리는 삭제 불가 — 여기 체크 추가 필요
        if (category.getIsDefaultYn().equals("Y")) {
        	throw new InvalidCategoryAccessException("기본카테고리는 삭제 불가능합니다!");
        }
        	
        // Mapper로 delete 호출
        personalCategoryMapper.deleteCategory(categoryNum);
    }
}