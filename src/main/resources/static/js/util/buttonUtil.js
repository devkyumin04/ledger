async function withButtonLock(button, asyncFn) {
    button.disabled = true;
    try {
        return await asyncFn();
    } finally {
        button.disabled = false;
    }
}