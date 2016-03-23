$( ->
  if $('#settings').length > 0
    updatePreview = (coords) ->
      # Update hidden fields
      $(["x", "y", "w", "h"]).each (index, attr) ->
        $("#collection_crop_" + attr).val coords[attr]

      # Update preview
      containerWidth = $("#preview-container").width()
      containerHeight = $("#preview-container").height()
      $("#preview").css
        width: Math.round(containerWidth / coords.w * $("#cropbox").width()) + "px"
        height: Math.round(containerHeight / coords.h * $("#cropbox").height()) + "px"
        marginLeft: "-" + Math.round(containerWidth / coords.w * coords.x) + "px"
        marginTop: "-" + Math.round(containerHeight / coords.h * coords.y) + "px"

    current_crop = null
    apply_jcrop = ->
      default_size = 400
      current_crop.destroy() if current_crop

      x1 = parseInt($('#collection_crop_x').val() || default_size/4)
      y1 = parseInt($('#collection_crop_y').val() || default_size/4)
      w = parseInt($('#collection_crop_w').val() || default_size/2)
      h = parseInt($('#collection_crop_h').val() || default_size/2)
      $("#cropbox").Jcrop {
          onSelect: updatePreview
          onChange: updatePreview
          setSelect: [x1, y1, x1 + w, y1 + h]
          aspectRatio: 1
        }, (api) -> current_crop = this

    show_editor = ->
      apply_jcrop()
      $('#logo-editor').show()
      $('#logo-display').hide()

    $('#edit-logo-button').on 'click', (ev) ->
      show_editor()
      ev.preventDefault()

    $("#logo-file-upload").fileupload({
      dataType: "json"
      type: 'POST'
      formData: {}
      acceptFileTypes: /(\.|\/)(gif|jpe?g|png)$/i
      maxFileSize: 4*1024*1024
      done: (e, data) ->
        $('#collection_logo_cache').val(data.result.cache_name)
        $('#cropbox').attr('src', data.result.croppable_url)
        $('#preview').attr('src', data.result.preview_url)
        show_editor()
    }).on('fileuploadprocessfail', (e, data) ->
      $.status.showError('Invalid logo: ' + data.files[data.index].error, 5000)
    ).on('fileuploadfail', (e, data) ->
      $.status.showError('Logo upload failed: ' + data.textStatus, 5000)
    )

    # If there is some logo cached, or there is some cropping values set, we
    # were editing it before, so start in editing mode
    if $('#collection_logo_cache').val() or $('#collection_crop_w').val()
      show_editor()
)
