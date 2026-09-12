package com.kyumin.ledger.exception;

public class InvalidTransactionAccessException extends RuntimeException{
	
	public InvalidTransactionAccessException(String message) {
		super(message);
	}
}
