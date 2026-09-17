// 여러 화면이 같이 쓰는 표시 함수. 받은 값을 보기 좋게 바꾸기만 한다 (계산·판단 없음)

function won(n) {
    return n.toLocaleString('ko-KR');
}

// 사용자 입력(카테고리 이름·이모지, 메모)은 innerHTML 에 넣기 전에 반드시 거친다
function escapeHtml(s) {
    return s.replace(/[&<>"']/g, c => ({
        '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
    }[c]));
}
