function requireLogin() {
    const token = localStorage.getItem('accessToken');

    if (!token) {
        window.location.href = '/views/user/login.html';
    }

    return token;
}