package com.kyumin.ledger.exception;

public class TransactionConflictException extends RuntimeException{
	
	public TransactionConflictException(String message) {
		super(message);
	}
}
