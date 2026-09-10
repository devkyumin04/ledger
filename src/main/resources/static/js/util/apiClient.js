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

    if (response.status === 401) {
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
