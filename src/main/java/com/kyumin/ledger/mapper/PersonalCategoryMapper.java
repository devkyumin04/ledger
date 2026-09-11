package com.kyumin.ledger.mapper;

import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.kyumin.ledger.domain.PersonalCategory;

@Mapper
public interface PersonalCategoryMapper {

    void insertCategory(PersonalCategory category);

    List<PersonalCategory> findByUserNum(Integer userNum);
    
    PersonalCategory findByCategoryNum(Integer categoryNum);
    
    void updateCategory(PersonalCategory category);
    
    void deleteCategory(Integer categoryNum);

    int countChildren(Integer categoryNum);
}