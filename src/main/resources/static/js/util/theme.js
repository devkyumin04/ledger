(function () {
    const saved = localStorage.getItem('theme');
    if (saved) {
        document.documentElement.dataset.theme = saved;
        return;
    }
    // 저장된 선택이 없으면 OS 설정을 따름
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    document.documentElement.dataset.theme = prefersDark ? 'dark' : 'light';
})();

// 사용자가 직접 고른 적 없으면, OS 설정이 바뀔 때 페이지도 따라감
window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
    if (!localStorage.getItem('theme')) {
        document.documentElement.dataset.theme = e.matches ? 'dark' : 'light';
    }
});

function toggleTheme() {
    const next = document.documentElement.dataset.theme === 'dark' ? 'light' : 'dark';
    document.documentElement.dataset.theme = next;
    localStorage.setItem('theme', next);
}
