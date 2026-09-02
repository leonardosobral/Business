(function (root, factory) {
    var api = factory();
    if (typeof module === "object" && module.exports) module.exports = api;
    if (root) root.RunProCampaignWizard = api;
}(typeof window !== "undefined" ? window : null, function () {
    "use strict";

    function parseMoney(value) {
        if (typeof value === "number") return Number.isFinite(value) ? value : 0;
        var normalized = String(value || "")
            .replace(/[^0-9,.-]/g, "")
            .replace(/\.(?=\d{3}(?:\D|$))/g, "")
            .replace(",", ".");
        var parsed = Number(normalized);
        return Number.isFinite(parsed) ? parsed : 0;
    }

    function estimateClicks(budget, cpc) {
        var total = parseMoney(budget);
        var bid = parseMoney(cpc);
        if (total <= 0 || bid <= 0) return { min: 0, max: 0 };
        var potentialClicks = total / bid;
        var max = Math.floor(potentialClicks);
        return {
            min: Math.round(potentialClicks * 0.75),
            max: max
        };
    }

    function suggestEndAt(eventDate, daysBefore) {
        if (!/^\d{4}-\d{2}-\d{2}$/.test(String(eventDate || ""))) return "";
        var parts = eventDate.split("-").map(Number);
        var date = new Date(Date.UTC(parts[0], parts[1] - 1, parts[2], 23, 59));
        if (Number.isNaN(date.getTime())) return "";
        date.setUTCDate(date.getUTCDate() - Math.max(0, Number(daysBefore) || 0));
        return date.toISOString().slice(0, 10) + "T23:59";
    }

    function isStepValid(step, values) {
        var data = values || {};
        if (Number(step) === 1) {
            return Number(data.eventId) > 0 && String(data.name || "").trim().length >= 3;
        }
        if (Number(step) === 2) {
            var cpc = parseMoney(data.cpc);
            var budget = parseMoney(data.budget);
            var daily = parseMoney(data.daily);
            return cpc >= 0.51 && budget > 0 && (!String(data.daily || "").trim() || (daily > 0 && daily <= budget));
        }
        if (Number(step) === 3) {
            var startsAt = new Date(data.startsAt);
            var endsAt = new Date(data.endsAt);
            return !Number.isNaN(startsAt.getTime())
                && !Number.isNaN(endsAt.getTime())
                && endsAt.getTime() > startsAt.getTime()
                && /^[A-Za-z]{2}$/.test(String(data.country || "").trim());
        }
        if (Number(step) === 4) {
            return Array.isArray(data.placements) && data.placements.length > 0;
        }
        return false;
    }

    function findStepButtons(form) {
        var shell = form && typeof form.closest === "function"
            ? form.closest(".ads-wizard-shell")
            : null;
        var scope = shell || form;
        if (!scope || typeof scope.querySelectorAll !== "function") return [];
        return Array.prototype.slice.call(scope.querySelectorAll("[data-wizard-step-button]"));
    }

    function initialMaxReached(isNew, currentStep, totalSteps) {
        var lastStep = Math.max(1, Number(totalSteps) || 1);
        var activeStep = Math.min(lastStep, Math.max(1, Number(currentStep) || 1));
        return isNew ? activeStep : lastStep;
    }

    function initWizard(form) {
        if (!form || form.dataset.wizardReady === "true") return;
        form.dataset.wizardReady = "true";

        var panels = Array.prototype.slice.call(form.querySelectorAll("[data-wizard-panel]"));
        var stepButtons = findStepButtons(form);
        var backButton = form.querySelector("#ads-wizard-back");
        var nextButton = form.querySelector("#ads-wizard-next");
        var submitButton = form.querySelector("#ads-wizard-submit");
        var eventSelect = form.querySelector("#ads-v1-event");
        var nameInput = form.querySelector("#ads-v1-name");
        var cpcInput = form.querySelector("#ads-v1-cpc");
        var budgetInput = form.querySelector("#ads-v1-total");
        var dailyInput = form.querySelector("#ads-v1-daily");
        var startsInput = form.querySelector("#ads-v1-start");
        var endsInput = form.querySelector("#ads-v1-end");
        var countryInput = form.querySelector("#ads-v1-country");
        var regionInput = form.querySelector("#ads-v1-region");
        var cpcOptions = Array.prototype.slice.call(form.querySelectorAll("input[name='ads_cpc_option']"));
        var placementInputs = Array.prototype.slice.call(form.querySelectorAll("input[name='placement_keys']"));
        var currentStep = Math.min(4, Math.max(1, Number(form.dataset.initialStep) || 1));
        var isNew = form.dataset.isNew === "true";
        var maxReached = initialMaxReached(isNew, currentStep, panels.length || 4);

        function valuesForStep(step) {
            if (step === 1) return { eventId: eventSelect.value, name: nameInput.value };
            if (step === 2) return { cpc: cpcInput.value, budget: budgetInput.value, daily: dailyInput.value };
            if (step === 3) return { startsAt: startsInput.value, endsAt: endsInput.value, country: countryInput.value };
            return { placements: placementInputs.filter(function (input) { return input.checked; }).map(function (input) { return input.value; }) };
        }

        function firstFieldForStep(step) {
            if (step === 1) return Number(eventSelect.value) > 0 ? nameInput : eventSelect;
            if (step === 2) {
                if (parseMoney(cpcInput.value) <= 0) return cpcInput;
                if (parseMoney(budgetInput.value) <= 0) return budgetInput;
                return dailyInput;
            }
            if (step === 3) {
                if (!startsInput.value) return startsInput;
                if (!endsInput.value || new Date(endsInput.value) <= new Date(startsInput.value)) return endsInput;
                return countryInput;
            }
            return placementInputs[0] || null;
        }

        function clearCustomValidity() {
            dailyInput.setCustomValidity("");
            endsInput.setCustomValidity("");
        }

        function validateStep(step, report) {
            clearCustomValidity();
            var values = valuesForStep(step);
            if (step === 2 && String(values.daily || "").trim() && parseMoney(values.daily) > parseMoney(values.budget)) {
                dailyInput.setCustomValidity("O limite diário não pode superar o orçamento total.");
            }
            if (step === 3 && values.startsAt && values.endsAt && new Date(values.endsAt) <= new Date(values.startsAt)) {
                endsInput.setCustomValidity("O fim precisa ser posterior ao início.");
            }
            var valid = isStepValid(step, values);
            var error = form.querySelector("[data-step-error='" + step + "']");
            if (error) error.classList.toggle("is-visible", !valid);
            if (!valid && report) {
                var field = firstFieldForStep(step);
                if (field && typeof field.reportValidity === "function") field.reportValidity();
                if (field && typeof field.focus === "function") field.focus();
            }
            return valid;
        }

        function showStep(step) {
            currentStep = Math.min(4, Math.max(1, Number(step) || 1));
            maxReached = Math.max(maxReached, currentStep);
            panels.forEach(function (panel) {
                panel.hidden = Number(panel.dataset.wizardPanel) !== currentStep;
            });
            stepButtons.forEach(function (button) {
                var buttonStep = Number(button.dataset.wizardStepButton);
                button.disabled = buttonStep > maxReached;
                button.classList.toggle("is-active", buttonStep === currentStep);
                button.classList.toggle("is-complete", buttonStep < currentStep && validateStep(buttonStep, false));
                if (buttonStep === currentStep) button.setAttribute("aria-current", "step");
                else button.removeAttribute("aria-current");
            });
            backButton.hidden = currentStep === 1;
            nextButton.hidden = currentStep === 4;
            submitButton.hidden = currentStep !== 4;
            var heading = form.querySelector("[data-wizard-panel='" + currentStep + "'] h3");
            if (heading) heading.setAttribute("tabindex", "-1");
        }

        function updateEstimate() {
            var estimate = estimateClicks(budgetInput.value, cpcInput.value);
            form.querySelector("#ads-estimate-min").textContent = String(estimate.min);
            form.querySelector("#ads-estimate-max").textContent = String(estimate.max);
            cpcOptions.forEach(function (option) {
                option.checked = Math.abs(parseMoney(option.value) - parseMoney(cpcInput.value)) < 0.001;
            });
        }

        function setPreviewImage(imageUrl, eventName) {
            var previewImage = form.querySelector("#ads-preview-image");
            var placeholder = form.querySelector("#ads-preview-image-placeholder");
            var placementImages = form.querySelectorAll("[data-event-placement-image]");
            if (imageUrl) {
                previewImage.src = imageUrl;
                previewImage.alt = "Imagem de " + eventName;
                previewImage.hidden = false;
                placeholder.hidden = true;
            } else {
                previewImage.removeAttribute("src");
                previewImage.alt = "";
                previewImage.hidden = true;
                placeholder.hidden = false;
            }
            Array.prototype.forEach.call(placementImages, function (image) {
                if (imageUrl) {
                    image.src = imageUrl;
                    image.hidden = false;
                } else {
                    image.removeAttribute("src");
                    image.hidden = true;
                }
            });
        }

        function updateEvent() {
            var option = eventSelect.options[eventSelect.selectedIndex];
            var hasEvent = option && option.value;
            var eventName = hasEvent ? option.dataset.eventName : "Selecione um evento vinculado";
            var city = hasEvent ? option.dataset.eventCity : "";
            var state = hasEvent ? option.dataset.eventState : "";
            var tag = hasEvent ? option.dataset.eventTag : "";
            var image = hasEvent ? option.dataset.eventImage : "";
            form.querySelector("#ads-preview-name").textContent = eventName;
            form.querySelector("#ads-preview-date").textContent = hasEvent ? option.dataset.eventDate : "";
            form.querySelector("#ads-preview-city").textContent = hasEvent ? city + (state ? "/" + state : "") : "";
            setPreviewImage(image, eventName);

            var previewLink = form.querySelector("#ads-preview-link");
            previewLink.href = tag ? "https://roadrunners.run/evento/" + encodeURIComponent(tag) + "/" : "#";
            previewLink.classList.toggle("disabled", !tag);

            if (hasEvent && isNew) {
                if (!nameInput.value.trim() || nameInput.dataset.autoSuggested === "true") {
                    nameInput.value = eventName + " — Divulgação";
                    nameInput.dataset.autoSuggested = "true";
                }
                if (!regionInput.value.trim()) regionInput.value = state;
                var suggestedEnd = suggestEndAt(option.dataset.eventEnd, 3);
                if (suggestedEnd) endsInput.value = suggestedEnd;
            }
        }

        nextButton.addEventListener("click", function () {
            if (!validateStep(currentStep, true)) return;
            showStep(currentStep + 1);
        });
        backButton.addEventListener("click", function () { showStep(currentStep - 1); });
        stepButtons.forEach(function (button) {
            button.addEventListener("click", function () {
                var requestedStep = Number(button.dataset.wizardStepButton);
                if (requestedStep <= maxReached) showStep(requestedStep);
            });
        });
        cpcOptions.forEach(function (option) {
            option.addEventListener("change", function () {
                if (option.checked) {
                    cpcInput.value = option.value;
                    updateEstimate();
                }
            });
        });
        [cpcInput, budgetInput].forEach(function (input) { input.addEventListener("input", updateEstimate); });
        dailyInput.addEventListener("input", clearCustomValidity);
        startsInput.addEventListener("change", clearCustomValidity);
        endsInput.addEventListener("change", clearCustomValidity);
        nameInput.addEventListener("input", function () { nameInput.dataset.autoSuggested = "false"; });
        eventSelect.addEventListener("change", updateEvent);
        placementInputs.forEach(function (input) {
            input.addEventListener("change", function () {
                var error = form.querySelector("[data-step-error='4']");
                if (error) error.classList.remove("is-visible");
                if (input.checked) form.querySelector("#ads-preview-location").textContent = input.dataset.placementLabel;
            });
        });
        Array.prototype.forEach.call(form.querySelectorAll("[data-preview-placement]"), function (button) {
            button.addEventListener("click", function () {
                Array.prototype.forEach.call(form.querySelectorAll("[data-preview-placement]"), function (item) { item.classList.remove("is-active"); });
                button.classList.add("is-active");
                form.querySelector("#ads-preview-location").textContent = button.dataset.previewPlacement;
            });
        });
        form.addEventListener("submit", function (event) {
            for (var step = 1; step <= 4; step += 1) {
                if (!validateStep(step, false)) {
                    event.preventDefault();
                    maxReached = Math.max(maxReached, step);
                    showStep(step);
                    validateStep(step, true);
                    return;
                }
            }
        });

        updateEvent();
        updateEstimate();
        showStep(currentStep);
    }

    if (typeof document !== "undefined") {
        if (document.readyState === "loading") {
            document.addEventListener("DOMContentLoaded", function () { initWizard(document.getElementById("ads-campaign-wizard")); });
        } else {
            initWizard(document.getElementById("ads-campaign-wizard"));
        }
    }

    return {
        estimateClicks: estimateClicks,
        findStepButtons: findStepButtons,
        initWizard: initWizard,
        initialMaxReached: initialMaxReached,
        isStepValid: isStepValid,
        parseMoney: parseMoney,
        suggestEndAt: suggestEndAt
    };
}));
