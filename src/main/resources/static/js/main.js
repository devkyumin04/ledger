const token = requireLogin();
const welcomeMessage = document.getElementById('welcomeMessage');
const logoutBtn = document.getElementById('logoutBtn');

async function loadMyInfo() {
    try {
        const response = await fetch('/api/users/me', {
            headers: { 'Authorization' : 'Bearer ' + token }
        });
        const data = await response.json();
        welcomeMessage.textContent = data.nickname + '님, 환영합니다';
    } catch (error) {
        console.error('내 정보 조회 실패', error);
    }
}

loadMyInfo();

logoutBtn.addEventListener('click', () => {
    localStorage.removeItem('accessToken');
    window.location.href = 'user/login.html';
});