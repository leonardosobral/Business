(function (window) {
    'use strict';
    var shared = window.OpenResultsEstadoCities;
    function cityUrl(href, city) {
        if (!city || !city.slug) return '';
        var source = new URL(href);
        if (!source.searchParams.has('rua') && !source.searchParams.has('trail')) {
            source.searchParams.set('rua','true');
            source.searchParams.set('trail','true');
        }
        return shared.buildUrl(source.href, city.uf, city.slug);
    }
    function findCities(cities, term, limit) {
        function exact(city) {
            var name = city.name;
            var fullName = name + ' ' + city.uf;
            return (shared.matches(name,term) && shared.matches(term,name)) || (shared.matches(fullName,term) && shared.matches(term,fullName));
        }
        return cities.filter(function (city) {
            return cityUrl('https://openresults.run/',city) && shared.matches(city.name + ' ' + city.uf,term);
        }).sort(function (a,b) {return Number(exact(b))-Number(exact(a));}).slice(0,limit);
    }
    function init(document) {
        var picker = document.querySelector('[data-home-city-picker]');
        var data = document.getElementById('home-city-data');
        if (!picker || !data || !shared) return;
        var cities;
        try {
            cities = JSON.parse(data.textContent).map(function (city) {
                return {name:city.name || city.NAME,uf:city.uf || city.UF,slug:city.slug || city.SLUG,total:Number(city.total || city.TOTAL)};
            });
        } catch (_) { return; }
        var input = picker.querySelector('input');
        var summary = picker.querySelector('summary');
        var suggestions = picker.querySelector('[data-home-city-suggestions]');
        var results = picker.querySelector('[data-home-city-results]');
        var status = picker.querySelector('[data-home-city-status]');
        function search() {
            var term = input.value.trim();
            suggestions.hidden = !!term;
            results.hidden = !term;
            results.replaceChildren();
            status.textContent = '';
            if (!term) return;
            var found = findCities(cities,term,30);
            found.forEach(function (city) {
                var link = document.createElement('a');
                link.className = 'estado-city-picker-item';
                link.href = cityUrl(window.location.href,city);
                var name = document.createElement('span');
                name.textContent = city.name + ' - ' + city.uf;
                var count = document.createElement('span');
                count.setAttribute('data-city-count','');
                count.textContent = city.total.toLocaleString('pt-BR') + (city.total === 1 ? ' prova no histórico' : ' provas no histórico');
                link.append(name,count);
                results.append(link);
            });
            status.textContent = found.length ? (found.length === 30 ? 'Mostrando até 30 cidades. Refine a busca pelo nome ou UF.' : found.length + (found.length === 1 ? ' cidade encontrada.' : ' cidades encontradas.')) : 'Nenhuma cidade encontrada.';
        }
        picker.addEventListener('toggle',function () {
            if (picker.open) input.focus();
            else {input.value='';search();}
        });
        input.addEventListener('input',search);
        picker.addEventListener('keydown',function (event) {
            if (event.key === 'Escape') {picker.open=false;summary.focus();}
        });
        document.addEventListener('click',function (event) {
            if (!picker.contains(event.target)) picker.open=false;
        });
        suggestions.querySelectorAll('[data-home-city-slug]').forEach(function (link) {
            var href = cityUrl(window.location.href,{uf:link.dataset.homeCityUf,slug:link.dataset.homeCitySlug});
            if (href) link.href=href;
        });
        input.disabled=false;
        input.placeholder='Digite o nome da cidade ou UF';
    }
    window.OpenResultsHomeCities = {findCities:findCities,cityUrl:cityUrl,init:init};
})(window);
