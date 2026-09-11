requireLogin();

let categories = [];
let currentType = 'E';

const listEl = document.getElementById('categoryList');
const modal = document.getElementById('categoryModal');
const form = document.getElementById('categoryForm');
const resultMessage = document.getElementById('resultMessage');

async function loadCategories() {
    const data = await apiRequest('/api/categories', 'GET');
	if(!data) return;
	categories = data;
    render();
}

function render() {
    const list = categories.filter(c => c.categoryType === currentType );             // 현재 탭 타입만
    const parents = list.filter(c => c.parentCategoryNum === null );                // 대분류만

    listEl.innerHTML = '';
    parents.forEach(p => {
        listEl.appendChild(createItem(p, false));
        list.filter(c => c.parentCategoryNum === p.categoryNum)                             // p의 자식들
            .forEach(child => listEl.appendChild(createItem(child, true)));
    });
}

function createItem(c, isChild) {
    const li = document.createElement('li');
    li.className = 'category-item' + (isChild ? ' child' : '');
    li.innerHTML = `
        <span>${c.categoryEmoji ?? '' } ${c.categoryName}</span>
        ${c.categoryName === '미분류' ? '' : `
        <span class="actions">
            <button data-action="edit" data-id="${c.categoryNum}">수정</button>
            <button data-action="delete" data-id="${c.categoryNum}">삭제</button>
        </span>`}
    `;
    return li;
}

loadCategories();

// 탭
document.querySelectorAll('.tab').forEach(tab => {
    tab.addEventListener('click', () => {
        currentType = tab.dataset.type;
        document.querySelectorAll('.tab').forEach(t => t.classList.toggle('active', t === tab));
       	render();
    });
});

// 추가
document.getElementById('addBtn').addEventListener('click', () => openModal(null));

// 목록 (위임)
listEl.addEventListener('click', (e) => {
    const btn = e.target.closest('button[data-action]');
    if (!btn) return;
    const id = Number(btn.dataset.id);
    if (btn.dataset.action === 'edit') openModal(id);
    if (btn.dataset.action === 'delete') removeCategory(id);
});

// 취소
document.getElementById('cancelBtn').addEventListener('click', closeModal);


function openModal(id) {
    form.reset();
    fillParentOptions(id);

    document.getElementById('editingId').value = id ?? '';          // id 없으면 빈 문자열
    document.getElementById('modalTitle').textContent = id ? '카테고리 수정' : '카테고리 추가';   // 수정/추가 분기

    if (id) {
        const c = categories.find(x => x.categoryNum === id);
        document.getElementById('categoryName').value = c.categoryName;
        document.getElementById('categoryEmoji').value = c.categoryEmoji ?? '';   // null이면 빈 문자열
        document.getElementById('parentCategoryNum').value = c.parentCategoryNum ?? '';
    }
    modal.hidden = false;
}

function closeModal() {
    modal.hidden = true;
    resultMessage.textContent = '';
}

function fillParentOptions(editingId) {
    const select = document.getElementById('parentCategoryNum');
    select.innerHTML = '<option value="">없음 (대분류)</option>';

    categories
        .filter(c => c.categoryType === currentType                    // 현재 탭 타입
                  && c.parentCategoryNum === null                    // 대분류만
                  && c.categoryName !== '미분류'                   // 미분류 제외
                  && c.categoryNum !== editingId)                   // 자기 자신 제외
        .forEach(c => select.add(new Option(c.categoryName, c.categoryNum)));

    const hasChildren = categories.some(c => c.parentCategoryNum === editingId);   // 부모가 editingId인 게 있나
    select.disabled = hasChildren;
}

// 저장 (추가 / 수정)
form.addEventListener('submit', async (e) => {
    e.preventDefault();

    const id = document.getElementById('editingId').value;
    const body = {
        categoryName: document.getElementById('categoryName').value.trim(),
        categoryEmoji: document.getElementById('categoryEmoji').value.trim() || null,
        categoryType: currentType,
        parentCategoryNum: document.getElementById('parentCategoryNum').value || null,
    };

    await withButtonLock(document.getElementById('submitBtn'), async () => {
        try {
            if (id) {
                await apiRequest(`/api/categories/${id}`, 'PUT', body);
            } else {
                await apiRequest('/api/categories', 'POST', body);
            }
            closeModal();
            await loadCategories();
        } catch (error) {
            resultMessage.textContent = error.message;
        }
    });
});

// 삭제
async function removeCategory(id) {
    if (!confirm('삭제하시겠습니까?')) return;

    try {
        await apiRequest(`/api/categories/${id}`, 'DELETE');
        await loadCategories();
    } catch (error) {
        resultMessage.textContent = error.message;
    }
}
