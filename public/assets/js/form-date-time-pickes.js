window.__onPageLoad = window.__onPageLoad || function (callback) {
	document.addEventListener("turbo:load", callback);
	document.addEventListener("DOMContentLoaded", callback);
};

window.__onPageLoad(() => {
	"use strict";

    $('.datepicker').pickadate({
        selectMonths: true,
        selectYears: true
    }),
    $('.timepicker').pickatime()


   
        $('#date-time').bootstrapMaterialDatePicker({
            format: 'YYYY-MM-DD HH:mm'
        });
        $('#date').bootstrapMaterialDatePicker({
            time: false
        });
        $('#time').bootstrapMaterialDatePicker({
            date: false,
            format: 'HH:mm'
        });
   


});
