(function (root, factory) {
    'use strict';
    var api = factory();
    if (typeof module === 'object' && module.exports) module.exports = api;
    else { root.RunnerHubPace = api; api.init(root.document, root); }
})(typeof window !== 'undefined' ? window : this, function () {
    'use strict';
    var states = 'AC AL AM AP BA CE DF ES GO MA MG MS MT PA PB PE PI PR RJ RN RO RR RS SC SE SP TO'.split(' ');
    function positive(value) { return typeof value === 'number' && Number.isFinite(value) && value > 0; }
    function decimal(value) {
        var text = String(value).trim();
        if (!/^\d+(?:[.,]\d+)?$/.test(text)) return NaN;
        return Number(text.replace(',', '.'));
    }
    function clock(hours, minutes, seconds, pace) {
        var parts = [hours, minutes, seconds].map(function (value) { return String(value).trim(); });
        if (!parts.every(function (v) { return /^\d+$/.test(v); })) return NaN;
        var h = Number(parts[0]), m = Number(parts[1]), s = Number(parts[2]);
        if (h > 9999 || m > (pace ? 999 : 59) || s > 59 || (pace && h !== 0)) return NaN;
        return h * 3600 + m * 60 + s;
    }
    function calculate(mode, distance, time, pace) {
        if (mode === 'pace') { if (!positive(distance) || !positive(time)) throw new Error('Informe distância e tempo válidos.'); pace = time / distance; }
        else if (mode === 'time') { if (!positive(distance) || !positive(pace)) throw new Error('Informe distância e pace válidos.'); time = distance * pace; }
        else if (mode === 'distance') { if (!positive(time) || !positive(pace)) throw new Error('Informe tempo e pace válidos.'); distance = time / pace; }
        else throw new Error('Escolha um cálculo válido.');
        if (!positive(distance) || distance < 0.001 || distance > 1000 || !positive(time) || time > 35999999 || !positive(pace) || pace > 59999) throw new Error('Use distância entre 0,001 e 1.000 km e tempos dentro dos limites dos campos.');
        return {mode:mode, distance:distance, time:time, pace:pace, speed:3600 / pace};
    }
    function duration(value, isPace) {
        var total = Math.round(value), seconds = total % 60, minutes = Math.floor(total / 60);
        if (isPace) return minutes + ':' + String(seconds).padStart(2, '0');
        return String(Math.floor(minutes / 60)).padStart(2, '0') + ':' + String(minutes % 60).padStart(2, '0') + ':' + String(seconds).padStart(2, '0');
    }
    function splits(result) {
        var step = Math.max(1, Math.ceil(result.distance / 100)), rows = [];
        for (var km = step; km < result.distance; km += step) rows.push({distance:km, time:km * result.pace});
        rows.push({distance:result.distance, time:result.time});
        return {step:step, rows:rows};
    }
    function calendar(result, state) {
        // The catalog filters whole-kilometre categories, including 21/42 km.
        var preset = [5,10,21.0975,42.195].find(function (d) { return Math.abs(result.distance - d) < 0.000001; });
        var low = Math.max(1, Math.floor(result.distance)), high = preset ? low : Math.ceil(result.distance);
        high = Math.max(low, high);
        var query = new URLSearchParams({busca_tipo:'eventos',busca_mode:'plain',distancia_inicio:String(low),distancia_fim:String(high)});
        state = String(state || '').toUpperCase();
        if (states.indexOf(state) >= 0) { query.set('estado', state); query.set('context_uf', state); }
        else query.set('context_uf', 'BR');
        return {href:'/busca/?' + query.toString(), label:'Encontrar provas de ' + low + (high !== low ? ' a ' + high : '') + ' km'};
    }
    function init(document, window) {
        var form = document.querySelector('[data-pace-form]');
        if (!form) return;
        var resultBox = document.querySelector('[data-pace-result]'), result = null;
        var distanceField = form.querySelector('#pace-distance');
        var presetField = form.querySelector('#pace-preset');
        var stateField = document.querySelector('#pace-state');
        var error = form.querySelector('[data-pace-error]');
        var number = function (n, digits) { return n.toLocaleString('pt-BR', {maximumFractionDigits:digits}); };
        function mode() { return form.querySelector('[name="pace-mode"]:checked').value; }
        function clear() {
            result = null; resultBox.hidden = true; error.textContent = '';
            form.querySelectorAll('[aria-invalid]').forEach(function (field) { field.removeAttribute('aria-invalid'); });
        }
        function syncMode() {
            clear();
            form.querySelectorAll('[data-pace-group]').forEach(function (group) {
                var hidden = group.dataset.paceGroup === mode();
                group.hidden = hidden;
                group.querySelectorAll('input,select').forEach(function (field) { field.disabled = hidden; });
            });
            form.querySelector('[data-pace-submit]').textContent = {pace:'Calcular pace', time:'Calcular tempo', distance:'Calcular distância'}[mode()];
        }
        function invalid(field, message) {
            field.setAttribute('aria-invalid','true'); error.textContent = message; field.focus(); return false;
        }
        function field(id) { return form.querySelector('#' + id); }
        function updateCalendar() {
            if (!result) return;
            var target = calendar(result, stateField.value), link = resultBox.querySelector('[data-pace-calendar]');
            link.href = target.href; link.textContent = target.label;
        }
        form.querySelectorAll('[name="pace-mode"]').forEach(function (radio) { radio.addEventListener('change',syncMode); });
        presetField.addEventListener('change', function () {
            if (presetField.value) distanceField.value = presetField.value.replace('.',',');
            else { distanceField.value = ''; distanceField.focus(); }
            clear();
        });
        distanceField.addEventListener('input', function () { presetField.value = ''; });
        form.addEventListener('input',clear);
        form.querySelectorAll('[data-clock-paste]').forEach(function (input) {
            input.addEventListener('paste', function (event) {
                var text = event.clipboardData && event.clipboardData.getData('text');
                if (!text || !/^\d{1,4}:[0-5]\d(?::[0-5]\d)?$/.test(text.trim())) return;
                var parts = text.trim().split(':'), prefix = input.dataset.clockPaste;
                if (prefix === 'rhythm' && parts.length !== 2) return;
                event.preventDefault();
                if (prefix === 'time') { field('pace-hours').value = parts.length === 3 ? parts.shift() : '0'; field('pace-minutes').value = parts[0]; field('pace-seconds').value = parts[1]; }
                else { field('pace-rhythm-minutes').value = parts[0]; field('pace-rhythm-seconds').value = parts[1]; }
                clear();
            });
        });
        form.addEventListener('submit', function (event) {
            event.preventDefault(); clear();
            var current = mode(), d = decimal(distanceField.value);
            var t = clock(field('pace-hours').value,field('pace-minutes').value,field('pace-seconds').value,false);
            var p = clock(0,field('pace-rhythm-minutes').value,field('pace-rhythm-seconds').value,true);
            if (current !== 'distance' && (!positive(d) || d < 0.001 || d > 1000)) return invalid(distanceField,'Informe uma distância de 0,001 a 1.000 km. Use vírgula ou ponto decimal, sem separador de milhares.');
            if (current !== 'time' && !positive(t)) return invalid(field('pace-hours'),'Informe um tempo maior que zero. Minutos e segundos devem estar entre 0 e 59.');
            if (current !== 'pace' && !positive(p)) return invalid(field('pace-rhythm-minutes'),'Informe um pace maior que zero, com segundos entre 0 e 59.');
            try { result = calculate(current,d,t,p); }
            catch (e) { return invalid(current === 'distance' ? field('pace-rhythm-minutes') : distanceField,e.message); }
            resultBox.hidden = false;
            resultBox.querySelector('[data-pace-label]').textContent = {pace:'Seu pace', time:'Tempo mantendo este pace', distance:'Distância mantendo este pace'}[current];
            resultBox.querySelector('[data-pace-value]').textContent = current === 'pace' ? duration(result.pace,true) + ' min/km' : (current === 'time' ? duration(result.time,false) : number(result.distance,4) + ' km');
            resultBox.querySelector('[data-pace-context]').textContent = number(result.distance,4) + ' km · ' + duration(result.time,false) + ' · ' + duration(result.pace,true) + ' min/km · ' + number(result.speed,2) + ' km/h';
            var splitData = splits(result), body = resultBox.querySelector('tbody'); body.textContent = '';
            resultBox.querySelector('[data-pace-split-label]').textContent = 'Parciais a cada ' + splitData.step + ' km, com o trecho final incluído.';
            splitData.rows.forEach(function (row) {
                var tr = document.createElement('tr'), km = document.createElement('th'), time = document.createElement('td');
                km.scope = 'row'; km.textContent = number(row.distance,4) + ' km'; time.textContent = duration(row.time,false); tr.append(km,time); body.appendChild(tr);
            });
            updateCalendar();
            window.dataLayer = window.dataLayer || [];
            window.dataLayer.push({event:'rr_pace_calculate',calculator_mode:current});
        });
        stateField.addEventListener('change',updateCalendar);
        resultBox.querySelector('[data-pace-calendar]').addEventListener('click',function () {
            if (result) { window.dataLayer = window.dataLayer || []; window.dataLayer.push({event:'rr_pace_calendar_click',calculator_mode:result.mode}); }
        });
        syncMode();
    }
    return {decimal:decimal,clock:clock,calculate:calculate,duration:duration,splits:splits,calendar:calendar,init:init};
});
