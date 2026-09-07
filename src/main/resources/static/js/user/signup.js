const form = document.getElementById('signupForm');
const submitBtn = document.getElementById('submitBtn');
const resultMessage = document.getElementById('resultMessage');

form.addEventListener('submit', async (e) => {
    e.preventDefault();

    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;
    const nickname = document.getElementById('nickname').value;

    await withButtonLock(submitBtn, async () => {
        try {
            const result = await apiRequest('/api/users/signup','POST' , { email, password, nickname });
            resultMessage.textContent = '회원가입 성공!';
        } catch (error) {
            resultMessage.textContent = error.message;
        }
    });
});