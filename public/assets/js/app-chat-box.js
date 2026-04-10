window.__onPageLoad = window.__onPageLoad || function (callback) {
	document.addEventListener("turbo:load", callback);
	document.addEventListener("DOMContentLoaded", callback);
};

window.__onPageLoad(() => {
	"use strict";

    new PerfectScrollbar('.chat-list');
    new PerfectScrollbar('.chat-content');


});
