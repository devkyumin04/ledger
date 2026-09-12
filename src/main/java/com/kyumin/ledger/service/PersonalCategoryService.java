package com.kyumin.ledger.service;

import java.util.List;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import lombok.RequiredArgsConstructor;

import com.kyumin.ledger.domain.PersonalCategory;
import com.kyumin.ledger.dto.CategoryRequestDto;
import com.kyumin.ledger.dto.CategoryResponseDto;
import com.kyumin.ledger.exception.CategoryNotFoundException;
import com.kyumin.ledger.exception.InvalidCategoryAccessException;
import com.kyumin.ledger.exception.InvalidCategoryHierarchyException;
import com.kyumin.ledger.exception.ReservedCategoryNameException;
import com.kyumin.ledger.mapper.PersonalCategoryMapper;
import com.kyumin.ledger.mapper.PersonalTransactionMapper;

@Service
@RequiredArgsConstructor
public class PersonalCategoryService {

    private final PersonalCategoryMapper personalCategoryMapper;
    private final PersonalTransactionMapper personalTransactionMapper;

    public CategoryResponseDto createCategory(Integer userNum, CategoryRequestDto requestDto) {
    	
    	if (PersonalCategory.DEFAULT_CATEGORY_NAME.equals(requestDto.getCategoryName().trim())) {
    	    throw new ReservedCategoryNameException("사용할 수 없는 카테고리 이름입니다.");
    	}
    	
    	validateParent(userNum, requestDto.getParentCategoryNum(), requestDto.getCategoryType(), null);
    	  
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
    
    private void validateParent(Integer userNum, Integer parentNum, String categoryType, Integer selfNum) {
        if (parentNum == null) return;                                   // 대분류
        if (selfNum != null && parentNum.equals(selfNum)) throw new InvalidCategoryHierarchyException("자기 자신을 상위로 지정할 수 없습니다");     // 자기 자신 (조회 전)

        PersonalCategory parent = personalCategoryMapper.findByCategoryNum(parentNum);
        if (parent == null) throw new CategoryNotFoundException("존재하지 않는 카테고리입니다!");
        if (!parent.getUserNum().equals(userNum)) throw new InvalidCategoryAccessException("본인의 카테고리만 상위로 지정할 수 있습니다!");
        if (!parent.getCategoryType().equals(categoryType)) throw new InvalidCategoryHierarchyException("카테고리 타입이 불일치합니다!");
        if (parent.getParentCategoryNum() != null) throw new InvalidCategoryHierarchyException("카테고리는 2단계까지만 가능합니다");            // 부모가 소분류 → 3계층
        if ("Y".equals(parent.getIsDefaultYn())) throw new InvalidCategoryHierarchyException("기본 카테고리 아래에는 만들 수 없습니다");              // 미분류 아래
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
    	
    	if (PersonalCategory.DEFAULT_CATEGORY_NAME.equals(requestDto.getCategoryName().trim())) {
    	    throw new ReservedCategoryNameException("사용할 수 없는 카테고리 이름입니다.");
    	}
    	
        PersonalCategory category = personalCategoryMapper.findByCategoryNum(categoryNum);

        if (category == null) {
            throw new CategoryNotFoundException("존재하지 않는 카테고리입니다!");
        }

        if (!category.getUserNum().equals(userNum)) {
            throw new InvalidCategoryAccessException("본인의 카테고리만 수정할 수 있습니다!");
        }

        if ("Y".equals(category.getIsDefaultYn())) {
            throw new InvalidCategoryAccessException("기본카테고리는 수정 불가능합니다!");
        }
        
        validateParent(userNum, requestDto.getParentCategoryNum(), category.getCategoryType(), categoryNum);

        if (requestDto.getParentCategoryNum() != null && personalCategoryMapper.countChildren(categoryNum) > 0) {
            throw new InvalidCategoryHierarchyException("하위 카테고리가 있으면 소분류로 바꿀 수 없습니다.");
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
    
    @Transactional
    public void deleteCategory(Integer userNum, Integer categoryNum) {

        PersonalCategory category = personalCategoryMapper.findByCategoryNum(categoryNum);

        if (category == null) {
            throw new CategoryNotFoundException("존재하지 않는 카테고리입니다!");
        }

        if (!category.getUserNum().equals(userNum)) {
            throw new InvalidCategoryAccessException("본인의 카테고리만 삭제할 수 있습니다!");
        }

        // '미분류' 카테고리는 삭제 불가 
        if ("Y".equals(category.getIsDefaultYn())) {
        	throw new InvalidCategoryAccessException("기본카테고리는 삭제 불가능합니다!");
        }

        if (personalCategoryMapper.countChildren(categoryNum) > 0) {
            throw new InvalidCategoryHierarchyException("하위 카테고리를 먼저 삭제해주세요.");
        }
        
        //미분류 카테고리는 singup에서 항상 생성, sql로 직접 넣은 유저만 null
        PersonalCategory defaultCategory = personalCategoryMapper.findDefaultCategory(userNum, category.getCategoryType());
        personalTransactionMapper.moveToDefaultCategory(categoryNum, defaultCategory.getCategoryNum());
        
        // Mapper로 delete 호출
        personalCategoryMapper.deleteCategory(categoryNum);
    }
}