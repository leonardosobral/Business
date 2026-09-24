(function (root) {
    'use strict';
    function selectionValid(mode, values) { return mode === 'ALL' || (mode === 'SELECTED' && values.length > 0); }
    async function inspectPreview(file, urls, decode) {
        if (file.size > 10485760) throw new Error('A imagem deve ter até 10 MiB.');
        var url = urls.createObjectURL(file);
        try {
            var image = await decode(url);
            if (!image.width || !image.height || image.width * image.height > 40000000) throw new Error('A imagem deve ter até 40 megapixels.');
            return {url: url, width: image.width, height: image.height};
        } catch (error) { urls.revokeObjectURL(url); throw error; }
    }
    function init(form) {
        ['pages', 'regions'].forEach(function (kind) {
            var mode = form.elements['banner_' + kind + '_mode'];
            var choices = Array.from(form.querySelectorAll('[name="banner_' + kind + '"]'));
            var group = form.querySelector('[data-banner-choices="' + kind + '"]');
            function update() {
                group.hidden = mode.value !== 'SELECTED';
                mode.setCustomValidity(selectionValid(mode.value, choices.filter(function (c) {return c.checked;})) ? '' : 'Selecione pelo menos uma opção.');
            }
            mode.addEventListener('change', update); choices.forEach(function (c) {c.addEventListener('change', update);}); update();
        });
        form.querySelectorAll('[data-banner-upload]').forEach(function (input) {
            var preview = form.querySelector('[data-banner-preview="' + input.dataset.bannerUpload + '"]');
            var info = form.querySelector('[data-banner-info="' + input.dataset.bannerUpload + '"]');
            var savedPreview = preview.hidden ? '' : preview.src;
            var currentUrl = ''; var sequence = 0;
            input.addEventListener('change', async function () {
                var mine=++sequence;
                if(currentUrl) {URL.revokeObjectURL(currentUrl); currentUrl='';}
                input.setCustomValidity(''); info.textContent='';
                if (!input.files.length) {preview.src=savedPreview;preview.hidden=!savedPreview;return;}
                try {
                    var result = await inspectPreview(input.files[0], URL, function (url) {return new Promise(function (resolve,reject) {var img=new Image();img.onload=function(){resolve({width:img.naturalWidth,height:img.naturalHeight});};img.onerror=function(){reject(new Error('Arquivo de imagem inválido.'));};img.src=url;});});
                    if (mine!==sequence) {URL.revokeObjectURL(result.url); return;}
                    currentUrl=result.url;preview.src=result.url;preview.hidden=false;info.textContent=result.width+' × '+result.height+' px';
                } catch (e) {if(mine===sequence){input.setCustomValidity(e.message);info.textContent=e.message;preview.hidden=true;}}
            });
        });
    }
    var api={selectionValid:selectionValid,inspectPreview:inspectPreview,init:init};
    if(typeof module==='object' && module.exports) module.exports=api;
    if(root.document) root.document.querySelectorAll('[data-banner-form]').forEach(init);
})(typeof window!=='undefined' ? window : globalThis);
