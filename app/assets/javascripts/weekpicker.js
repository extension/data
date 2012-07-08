// http://igorzelmanovich.blogspot.com/2011/07/week-picker-using-jquery-ui-datepicker.html

$(function() {   
    var startDate;
    var endDate;

    var selectCurrentWeek = function () {
        window.setTimeout(function () {
            $('.ui-weekpicker').find('.ui-datepicker-current-day a').addClass('ui-state-active').removeClass('ui-state-default');
        }, 1);
    }

    var setDates = function (input) {
        var $input = $(input);
        var date = $input.datepicker('getDate');
        if (date !== null) {
            var firstDay = $input.datepicker( "option", "firstDay" );
            var dayAdjustment = date.getDay() - firstDay;
            if (dayAdjustment < 0) {
                dayAdjustment += 7;
            }
            startDate = new Date(date.getFullYear(), date.getMonth(), date.getDate() - dayAdjustment);
            endDate = new Date(date.getFullYear(), date.getMonth(), date.getDate() - dayAdjustment + 6);
        }
    }

    $('.week-picker').datepicker({
        firstDay: 1,
        buttonImage: '/assets/calendar_view_week.png',
        buttonImageOnly: true,
        changeMonth: true,
        changeYear: true,
        showOn: 'both',
        dateFormat: 'yy-mm-dd',
        beforeShow: function () {
            $('#ui-datepicker-div').addClass('ui-weekpicker');
            selectCurrentWeek();
        },
        onClose: function () {
            $('#ui-datepicker-div').removeClass('ui-weekpicker');
        },
        showOtherMonths: true,
        selectOtherMonths: true,
        onSelect: function (dateText, inst) {
            setDates(this);
            selectCurrentWeek();            
            $(this).change();
        },
        beforeShowDay: function (date) {
            var cssClass = '';
            if (date >= startDate && date <= endDate)
                cssClass = 'ui-datepicker-current-day';
            return [true, cssClass];
        },
        onChangeMonthYear: function (year, month, inst) {
            selectCurrentWeek();
        }
    });
    

    var $calendarTR = $('.ui-weekpicker .ui-datepicker-calendar tr');
    $calendarTR.live('mousemove', function () {
        $(this).find('td a').addClass('ui-state-hover');
    });
    $calendarTR.live('mouseleave', function () {
        $(this).find('td a').removeClass('ui-state-hover');
    });
});
