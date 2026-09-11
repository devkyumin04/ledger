const token = requireLogin();
const welcomeMessage = document.getElementById('welcomeMessage');
const logoutBtn = document.getElementById('logoutBtn');

async function loadMyInfo() {
    try {
        const data = await apiRequest('/api/users/me', 'GET');
        if (!data) return;
        welcomeMessage.textContent = data.nickname + '님, 환영합니다';
    } catch (error) {
        console.error('내 정보 조회 실패', error);
    }
}

loadMyInfo();

logoutBtn.addEventListener('click', () => {
    localStorage.removeItem('accessToken');
    window.location.href = '/views/user/login.html';
});