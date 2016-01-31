(function () {

    $(document).on('click', "#test-transformation", function (e) {

        alert(this.previousElementSibling.value);

        var dialog = $('<div class="modal fade in" aria-hidden="false" style="display: block">\
        <div id="modal" class="modal-dialog">\
            <div class="modal-content">\
                <div class="modal-header">\
                  <a href="#" class="close" data-dismiss="modal">&times;</a>\
                  <h3 class="modal-header-title">Find a File</h3>\
                </div>\
                <div class="modal-body">\
                    ...\
                </div>\
                <div class="modal-footer">\
                  <div class="btn btn-primary" id="next">\
                    <i class="icon-forward"></i>\
                        Next\
                  </div>\
                </div>\
            </div>\
          </div>')
            .modal({
                keyboard: true,
                backdrop: true,
                show: true
            })
            .on('hidden', function () {
                dialog.remove();
                dialog = null;
            });

        dialog.find('#next').unbind().click(function () {
           form = dialog.find('form');
            form.attr("data-remote", true);
            form.bind("ajax:complete", function(xhr, data, status) {
                dialog.find('.modal-body').html(data.responseText);
                file_name_selector = dialog.find('#forms_file_ref_file_name');
                if (file_name_selector.length)
                    file_name_selector.on('change', function () {
                        if (this.value.length)
                            dialog.find('#next').html('<i class="icon-ok"></i>Ok');
                        else
                            dialog.find('#next').html('<i class="icon-forward"></i>Next');
                    });
            });
            form.submit();
            return false;
        });

        setTimeout(function () {

            $.ajax({
                url: '/data/forms~file_ref/new?modal=true',
                beforeSend: function (xhr) {
                    xhr.setRequestHeader("Accept", "text/javascript");
                },
                success: function (data, status, xhr) {
                    dialog.find('.modal-body').html(data);
                },
                error: function (xhr, status, error) {
                    dialog.find('.modal-body').html(xhr.responseText);
                },
                dataType: 'text'
            });
        }, 200);
    });

}).call(this);
