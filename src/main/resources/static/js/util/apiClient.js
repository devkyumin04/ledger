async function apiRequest(url, method, body) {
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
    //  · 토큰을 보냈는데 401 → 만료·무효 → 로그인 화면으로
    //  · 토큰 없이 401 → 로그인 실패(이메일·비번 틀림) → 에러로 던져 화면이 문구를 보여주게.
    //    전엔 이것도 로그인 화면으로 새로고침해서 "비밀번호가 틀렸다" 문구가 안 보였다 (2026-09-23 화면 QA)
    if (response.status === 401 && token) {
        localStorage.removeItem('accessToken');
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
