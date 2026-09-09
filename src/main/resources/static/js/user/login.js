const form = document.getElementById('loginForm');
const submitBtn = document.getElementById('submitBtn');
const resultMessage = document.getElementById('resultMessage');

form.addEventListener('submit', async (e) => {
    e.preventDefault();

    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;

    await withButtonLock(submitBtn, async () => {
        try {
			const result = await apiRequest('/api/users/login', 'POST', { email, password });
			localStorage.setItem( 'accessToken' , result.accessToken );
			window.location.href = '../main.html';
        } catch (error) {
            resultMessage.textContent = error.message;
        }
    });
});