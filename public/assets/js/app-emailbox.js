window.__onPageLoad = window.__onPageLoad || function (callback) {
	document.addEventListener("turbo:load", callback);
	document.addEventListener("DOMContentLoaded", callback);
};

window.__onPageLoad(() => {
	"use strict";

    new PerfectScrollbar('.email-navigation');
    new PerfectScrollbar('.email-list');


});
