function requireLogin() {
    const token = localStorage.getItem('accessToken');

    if (!token) {
        window.location.href = 'user/login.html';
    }

    return token;
}