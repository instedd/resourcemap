$( ->
  if $('#settings').length > 0
    if $("#cropbox").length
      update = (coords) ->

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

      $("#cropbox").Jcrop
        onSelect: update
        onChange: update
        aspectRatio: 150.0 / 150.0

);
