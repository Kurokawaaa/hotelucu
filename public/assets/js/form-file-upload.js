window.__onPageLoad = window.__onPageLoad || function (callback) {
	document.addEventListener("turbo:load", callback);
	document.addEventListener("DOMContentLoaded", callback);
};

window.__onPageLoad(() => {
	"use strict";

    $('#fancy-file-upload').FancyFileUpload({
        params: {
            action: 'fileuploader'
        },
        maxfilesize: 1000000
    });

    $(document).ready(function () {
        $('#image-uploadify').imageuploadify();
    })


});
