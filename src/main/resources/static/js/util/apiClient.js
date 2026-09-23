// options.silentExpire — 만료 토큰이어도 로그인 화면으로 보내지 않고 { status: 401, expired: true } 를 던진다.
// 공개 화면(메인)용: 만료면 조용히 비로그인 모습으로 보여 준다. Refresh 토큰 7단계에서 apiClient 를 다시 쓸 때 같이 정리
async function apiRequest(url, method, body, options = {}) {
    const headers = { 'Content-Type': 'application/json' };

    const token = localStorage.getItem('accessToken');
    if (token) {
        headers['Authorization'] = 'Bearer ' + token;
    }

    const response = await fetch(url, {
        method: method,
        headers: headers,
        body: body ? JSON.stringify(body) : null,
    });

    // 401 은 두 가지다
    //  · 토큰을 보냈는데 401 → 만료·무효 → 로그인 화면으로 (쓰던 중이니 다시 로그인해서 이어 가게)
    //  · 토큰 없이 401 → 로그인 실패(이메일·비번 틀림) → 에러로 던져 화면이 문구를 보여주게.
    //    전엔 이것도 로그인 화면으로 새로고침해서 "비밀번호가 틀렸다" 문구가 안 보였다 (2026-09-23 화면 QA)
    if (response.status === 401 && token) {
        localStorage.removeItem('accessToken');
        if (options.silentExpire) {
            throw { status: 401, expired: true };
        }
        window.location.href = '/views/user/login.html';
        return;
    }

    if (!response.ok) {
        const errorText = await response.text();
        throw { status: response.status, message: errorText };
    }

    if (response.status === 204) {
        return null;
    }

    return await response.json();
}
