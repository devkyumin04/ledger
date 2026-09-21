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

// 예시 화면의 막대 너비 — CSP 가 HTML 의 style 속성을 막으므로 JS 로 준다
document.querySelectorAll('.bar[data-width]').forEach(bar => {
    bar.style.width = bar.dataset.width + '%';
});

logoutBtn.addEventListener('click', () => {
    localStorage.removeItem('accessToken');
    window.location.href = '/views/user/login.html';
});