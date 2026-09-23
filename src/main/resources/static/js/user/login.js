const form = document.getElementById('loginForm');
const submitBtn = document.getElementById('submitBtn');
const resultMessage = document.getElementById('resultMessage');

form.addEventListener('submit', async (e) => {
    e.preventDefault();

    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;

    // 남아 있던 옛 토큰을 지우고 시작 — 토큰이 붙어 가면 로그인 실패(401)가 "세션 만료"로 오해된다 (apiClient.js)
    localStorage.removeItem('accessToken');

    await withButtonLock(submitBtn, async () => {
        try {
			const result = await apiRequest('/api/users/login', 'POST', { email, password });
			localStorage.setItem( 'accessToken' , result.accessToken );
			window.location.href = '/views/main.html';
        } catch (error) {
            resultMessage.textContent = error.message;
            // 이메일은 남기고 비밀번호만 비운다 — 틀린 값 위에 이어 치지 않게, 화면에 비번이 남지 않게
            const passwordInput = document.getElementById('password');
            passwordInput.value = '';
            passwordInput.focus();
        }
    });
});