window.__onPageLoad = window.__onPageLoad || function (callback) {
	document.addEventListener("turbo:load", callback);
	document.addEventListener("DOMContentLoaded", callback);
};

window.__onPageLoad(() => {
	"use strict";
    
	$(function () {
        $('[data-bs-toggle="popover"]').popover();
        $('[data-bs-toggle="tooltip"]').tooltip();
    })


});
