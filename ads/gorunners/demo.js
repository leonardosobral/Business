(() => {
    const byId = id => document.getElementById(id);
    const area = byId('demo-area');
    const order = byId('demo-order');
    const pointsInput = byId('zone-area');
    const start = byId('demo-start');
    const end = byId('demo-end');
    const brand = byId('demo-brand');
    const next = byId('demo-next');
    const edit = byId('demo-edit');
    const money = new Intl.NumberFormat('pt-BR', {style: 'currency', currency: 'BRL'});
    const displayDate = new Intl.DateTimeFormat('pt-BR', {timeZone: 'UTC'});
    const dayMs = 86400000;
    const dailyPrice = 10;
    let step = '';

    function inputDate(date) {
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const day = String(date.getDate()).padStart(2, '0');
        return date.getFullYear() + '-' + month + '-' + day;
    }
    const today = new Date();
    const weekLater = new Date(today);
    weekLater.setDate(weekLater.getDate() + 7);
    start.min = start.value = inputDate(today);
    end.value = inputDate(weekLater);

    function updateEndMin() {
        end.min = start.value && Number.isFinite(start.valueAsNumber)
            ? new Date(start.valueAsNumber + dayMs).toISOString().split('T')[0] : start.min;
    }
    start.addEventListener('input', updateEndMin);
    updateEndMin();

    byId('demo-example').addEventListener('click', () => {
        pointsInput.value = JSON.stringify([[-46.6612,-23.5881],[-46.6558,-23.5881],[-46.6558,-23.5845],[-46.6612,-23.5845]]);
        pointsInput.dispatchEvent(new Event('change', {bubbles:true}));
        byId('demo-error').textContent = 'Área de exemplo selecionada no Parque Ibirapuera, em São Paulo.';
    });

    function validArea(points) {
        if (!Array.isArray(points) || points.length < 3 || points.length > 100) return false;
        if (!points.every(p => Array.isArray(p) && p.length === 2 && p.every(Number.isFinite)
            && Math.abs(p[0]) <= 180 && Math.abs(p[1]) <= 85)) return false;
        const xs = points.map(p => p[0]);
        const ys = points.map(p => p[1]);
        if ((Math.max(...xs)-Math.min(...xs)) * (Math.max(...ys)-Math.min(...ys)) > 0.1) return false;
        const [x0, y0] = points[0];
        let twiceArea = 0;
        for (let i = 1; i < points.length-1; i++) {
            twiceArea += (xs[i]-x0)*(ys[i+1]-y0) - (xs[i+1]-x0)*(ys[i]-y0);
        }
        return Math.abs(twiceArea) > 1e-12;
    }

    function showStep(name, title, message, action) {
        step = name;
        byId('demo-title').textContent = title;
        byId('demo-message').textContent = message;
        byId('demo-sponsor').hidden = step !== 'reserved';
        edit.hidden = step !== 'quoted';
        next.textContent = action;
        area.hidden = true;
        order.hidden = false;
        byId('demo-title').focus();
    }
    byId('demo-quote').addEventListener('click', () => {
        let points;
        try { points = JSON.parse(pointsInput.value); } catch { points = []; }
        if (!validArea(points)) {
            byId('demo-error').textContent = 'Marque ao menos três pontos que formem uma área pequena ou use a área de exemplo.';
            return;
        }
        byId('demo-error').textContent = '';
        if (!start.reportValidity() || !end.reportValidity()) return;
        const days = (end.valueAsNumber - start.valueAsNumber) / dayMs;
        if (days <= 0) return;
        byId('demo-period').textContent = displayDate.format(start.valueAsNumber) + ' a ' + displayDate.format(end.valueAsNumber)
            + ' (término exclusivo) · ' + (days === 1 ? '1 dia' : days + ' dias');
        byId('demo-price').textContent = 'Valor simulado: ' + money.format(days * dailyPrice);
        showStep('quoted', 'Cotação de exemplo', 'Nesta demonstração, qualquer área custa ' + money.format(dailyPrice) + ' por dia. Na venda, o GoRunners calcula o preço e verifica a disponibilidade.', 'Simular reserva');
    });
    edit.addEventListener('click', () => {
        order.hidden = true;
        area.hidden = false;
        window.dispatchEvent(new Event('resize'));
        area.querySelector('h2').focus();
    });
    next.addEventListener('click', () => {
        switch (step) {
            case 'quoted':
                showStep('reserved', 'Reserva simulada', 'Escolha uma marca fictícia para o pedido.', 'Criar pedido de exemplo');
                break;
            case 'reserved':
                brand.value = brand.value.trim();
                brand.setCustomValidity(brand.value.length < 2 ? 'Informe uma marca com ao menos duas letras.' : '');
                if (!brand.reportValidity()) return;
                showStep('ordered', 'Pedido de exemplo criado', 'Patrocinador: ' + brand.value + '. O pedido aguarda o pagamento simulado.', 'Abrir pagamento simulado');
                break;
            case 'ordered':
                showStep('checkout', 'Pagamento simulado', 'Confirme o valor acima para testar a aprovação. Você não precisa informar dados de cartão ou Pix.', 'Simular aprovação do pagamento');
                break;
            case 'checkout':
                showStep('paid', 'Pagamento simulado aprovado', 'Fluxo concluído para ' + brand.value + '. A zona de exemplo não é publicada no mapa do jogo.', 'Iniciar outra simulação');
                break;
            case 'paid':
                window.location.reload();
                break;
        }
    });
    brand.addEventListener('input', () => brand.setCustomValidity(''));
})();
