const searchInputName = document.getElementById('searchInputName');
const searchInputNumber = document.getElementById('searchInputNumber');
const searchInputEquipe = document.getElementById('searchInputEquipe');

const table = document.getElementById('table');
const rows = table.getElementsByTagName('tr');

let noResultsRow;

// FILTRO POR NOME
searchInputName.addEventListener('keyup', function() {
    const searchText = searchInputName.value.toUpperCase();
    let resultsFound = false;

    if (noResultsRow) {
        table.removeChild(noResultsRow);
        noResultsRow = null;
    }

    for (let i = 2; i < rows.length; i++) {
        const name = rows[i].getElementsByTagName('td')[3];
        const link = name.querySelector('a.perfil');
        const nameText = link.textContent.toUpperCase();

        if (nameText.includes(searchText)) {
            rows[i].style.display = '';
            const regex = new RegExp(searchText , 'gi');
            //name.innerHTML = nameText.replace(regex, match =>`<span class="highlight"><a href="/resultados/#lcase(replace(nome, ' ', '-', 'ALL'))#/>"${match}</a></span>`);
            link.innerHTML = nameText.replace(regex , match =>`<span class="highlight">${match}</span>`);
            resultsFound = true;
        } else {
            rows[i].style.display = 'none';
            link.innerHTML =  nameText;
        }
    }

    if (!resultsFound) {
        noResultsRow = document.createElement('tr');
        const noResultsCell = document.createElement('td');
        noResultsCell.setAttribute('colspan', '2');
        noResultsCell.textContent = 'Nome não encontrado';
        noResultsRow.appendChild(noResultsCell);
        table.appendChild(noResultsRow);
    }
});

// FILTRO POR NUMERO
searchInputNumber.addEventListener('keyup', function() {
    const searchNumber = searchInputNumber.value.toUpperCase();
    let resultsFound = false;

    if (noResultsRow) {
        table.removeChild(noResultsRow);
        noResultsRow = null;
    }

    for (let i = 2; i < rows.length; i++) {
        const number = rows[i].getElementsByTagName('td')[2];
        const numberPeito = number.textContent.toUpperCase();

        if (numberPeito.includes(searchNumber)) {
            rows[i].style.display = '';
            const regex = new RegExp(searchNumber, 'gi');
            number.innerHTML = numberPeito.replace(regex, match => `<span class="highlight">${match}</span>`);
            resultsFound = true;
        } else {
            rows[i].style.display = 'none';
            number.innerHTML = numberPeito;
        }
    }

    if (!resultsFound) {
        noResultsRow = document.createElement('tr');
        const noResultsCell = document.createElement('td');
        noResultsCell.setAttribute('colspan', '2');
        noResultsCell.textContent = 'Número não encontrado';
        noResultsRow.appendChild(noResultsCell);
        table.appendChild(noResultsRow);
    }
});

// FILTRO POR EQUIPE
searchInputEquipe.addEventListener('keyup', function() {
    const searchEquipe = searchInputEquipe.value.toUpperCase();
    let resultsFound = false;

    if (noResultsRow) {
        table.removeChild(noResultsRow);
        noResultsRow = null;
    }

    for (let i = 2; i < rows.length; i++) {
        const Time = rows[i].getElementsByTagName('td')[4];
        const link = Time.querySelector('a');
        const TimeNew = link.textContent.toUpperCase();
        if (TimeNew.includes(searchEquipe)) {
            rows[i].style.display = '';
            const regex = new RegExp(searchEquipe, 'gi');
            //Time.innerHTML = TimeNew.replace(regex, match => `<span class="highlight"><a href="/evento/#tag#/?modalidade=#modalidade#&genero=#sexo#&equipe=#equipe#">${match}</a></span>`);
            link.innerHTML = TimeNew.replace(regex, match => `<span class="highlight">${match}</span>`);
            resultsFound = true;
        } else {
            rows[i].style.display = 'none';
            link.innerHTML = TimeNew;
        }
    }

    if (!resultsFound) {
        noResultsRow = document.createElement('tr');
        const noResultsCell = document.createElement('td');
        noResultsCell.setAttribute('colspan', '2');
        noResultsCell.textContent = 'Equipe não encontrada';
        noResultsRow.appendChild(noResultsCell);
        table.appendChild(noResultsRow);
    }
});
