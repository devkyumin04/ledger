// 로그인이 필요한 화면의 첫 줄에서 부른다. 토큰이 없으면 이유를 알리고 로그인으로 보낸다
// 메인이 아니라 로그인인 이유 — 이 주소로 온 사람은 그 기능을 쓰려는 사람이라 한 단계라도 짧게 (2026-09-23 판단)
// (메인은 공개 화면이라 이걸 부르지 않는다 — 메인의 안내는 main.js)
function requireLogin() {
    const token = localStorage.getItem('accessToken');

    if (!token) {
        alert('로그인이 필요합니다.');
        window.location.href = '/views/user/login.html';
    }

    return token;
}
