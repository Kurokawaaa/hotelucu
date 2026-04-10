window.__onPageLoad = window.__onPageLoad || function (callback) {
	document.addEventListener("turbo:load", callback);
	document.addEventListener("DOMContentLoaded", callback);
};

window.__onPageLoad(() => {
	"use strict";

    feather.replace()


});
