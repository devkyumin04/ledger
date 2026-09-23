// 메인은 공개 화면 — 로그인 안 한 사람(처음 온 사람·SES 심사자)도 소개를 본다.
// 기본 HTML 은 비로그인 모양이라 JS 가 안 돌아도 소개가 보인다. 토큰이 있을 때만 환영 문구·마이페이지·로그아웃
const token = localStorage.getItem('accessToken');
const welcomeMessage = document.getElementById('welcomeMessage');
const logoutBtn = document.getElementById('logoutBtn');
const loginLink = document.getElementById('loginLink');
const signupLink = document.getElementById('signupLink');
const mypageLink = document.getElementById('mypageLink');
const loginNotice = document.getElementById('loginNotice');

async function loadMyInfo() {
    try {
        const data = await apiRequest('/api/users/me', 'GET');
        if (!data) return;
        welcomeMessage.textContent = data.nickname + '님, 환영합니다';
    } catch (error) {
        console.error('내 정보 조회 실패', error);
    }
}

if (token) {
    loginLink.hidden = true;
    signupLink.hidden = true;
    mypageLink.hidden = false;
    logoutBtn.hidden = false;
    loadMyInfo();
} else {
    // 비로그인 상태에서 가계부·카테고리·통계로 가는 링크를 누르면 — 말없이 튕기지 않고 알린 뒤 로그인으로
    document.querySelectorAll('a[href^="/views/personal/"]').forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault();
            loginNotice.hidden = false;
            loginNotice.scrollIntoView({ block: 'nearest' });
            setTimeout(() => {
                window.location.href = '/views/user/login.html';
            }, 1200);
        });
    });
}

// 예시 화면의 막대 너비 — CSP 가 HTML 의 style 속성을 막으므로 JS 로 준다
document.querySelectorAll('.bar[data-width]').forEach(bar => {
    bar.style.width = bar.dataset.width + '%';
});

logoutBtn.addEventListener('click', () => {
    localStorage.removeItem('accessToken');
    window.location.href = '/views/main.html';
});
