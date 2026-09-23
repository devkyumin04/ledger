package com.kyumin.dotoree.exception;

public class TransactionConflictException extends RuntimeException{
	
	public TransactionConflictException(String message) {
		super(message);
	}
}
