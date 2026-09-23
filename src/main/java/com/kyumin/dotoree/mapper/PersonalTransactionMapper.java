package com.kyumin.dotoree.mapper;

import java.time.LocalDate;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.kyumin.dotoree.domain.PersonalTransaction;
import com.kyumin.dotoree.dto.PersonalTransactionResponseDto;

@Mapper
public interface PersonalTransactionMapper {

    void insertTransaction(PersonalTransaction transaction);

    List<PersonalTransactionResponseDto> findByMonth(@Param("userNum") Integer userNum,
                                                     @Param("startDate") LocalDate startDate,
                                                     @Param("endDate") LocalDate endDate);

    PersonalTransaction findByTransNum(@Param("transNum") Integer transNum);

    int updateTransaction(PersonalTransaction transaction);

    int deleteTransaction(@Param("transNum") Integer transNum,
                          @Param("version") Integer version);

    int moveToDefaultCategory(@Param("oldCategoryNum") Integer oldCategoryNum,
                              @Param("newCategoryNum") Integer newCategoryNum);

}