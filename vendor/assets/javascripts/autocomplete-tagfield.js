/*!
 * autocomplete tagfield v0.1
 * http://www.superbly.ch
 *
 * Copyright 2011, Manuel Spierenburg
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://www.superbly.ch/licenses/mit-license.txt
 * http://www.superbly.ch/licenses/gpl-2.0.txt
 *
 * Date: Sun Apr 14 00:47:29 2011 -0500
 */
(function($) {
	$.fn.autocompleteTagField = function(userOptions) {
		var settings = {
			allowNewTags : true,
			showTagsNumber : 10,
			addItemOnBlur : false,
			preset : [], // array of object [{id: 1, name: "site1", ...}]
			minChar : 3
		};

		if (userOptions) {
			$.extend(settings, userOptions);
		}

		autocompleteTagField(this, settings);

		return this;
	};

	var keyMap = {
		downArrow : 40,
		upArrow : 38,
		enter : 13,
		tab : 9,
		backspace : 8,
		escape : 27
	}

	function autocompleteTagField(tagField, settings) {
		var proxy = settings.proxy;
		var minChar = settings.minChar;
		var displayField = settings.displayField;
		var valueField = settings.valueField;

		var preset = settings.preset;
		var allowNewTags = settings.allowNewTags;
		var showTagsNumber = settings.showTagsNumber;
		var addItemOnBlur = settings.addItemOnBlur;
		
		// prepare needed vars
		var inserted = new Array();
		// array of object
		var suggestionList = new Array();
		
		// state of remote proxy data loaded
		var isProxyLoaded = false;
		// store an array of object that response from proxy
		var selectedIndex = null;
		var currentValue = null;
		var currentItem = null;
		var hoverSuggestItems = false;

		tagField.css('display', 'none');

		var autocompleteMarkup = '<div class="superblyTagfieldDiv"><ul class="superblyTagItems"><li class="superblyTagInputItem"><input class="superblyTagInput" type="text" autocomplete="false"><ul class="superblySuggestItems"></ul></li></ul><div class="superblyTagfieldClearer"></div></div>';
		tagField.after(autocompleteMarkup);

		var tagInput = $(".superblyTagInput", tagField.next());
		var suggestList = tagInput.next();
		var inputItem = tagInput.parent();
		var tagList = inputItem.parent();

		// set presets
		for(i=0; i<preset.length; i++) {
			addItem(preset[i]);
		}

		// events
		suggestList.mouseover(function(e) {
			hoverSuggestItems = true;
		});

		suggestList.mouseleave(function(e) {
			hoverSuggestItems = false;
		});

		tagInput.keyup(function(e) {
			suggest($(this).val());
		});

		tagInput.focusout(function(e) {
			if (!hoverSuggestItems) {
				hide();
			}
		});

		tagInput.focus(function(e) {
			currentValue = null;
			suggest($(this).val());
		});

		tagInput.keydown(function(e) {
			if (e.keyCode == keyMap.downArrow) {
				selectDown();
			} else if (e.keyCode == keyMap.upArrow) {
				selectUp()
			} else if (e.keyCode == keyMap.enter || e.keyCode == keyMap.tab) {
				checkForItem();
				// prevent default action for enter
				return e.keyCode != keyMap.enter;
			} else if (e.keyCode == keyMap.escape) {
				hide();
			} else if (e.keyCode == keyMap.backspace) {
				// backspace
				if (tagInput.val() == '') {
					removeLastItem();
				} else {
					hide();
				}
				updateTagInputWidth();
			} else {
				updateTagInputWidth();
			}

		});

		if (addItemOnBlur) {
			tagInput.blur(function(e) {
				checkForItem();
			});
		}

		tagList.parent().click(function(e) {
			tagInput.focus();
		});

		// functions
		function setValue() {
      tagField.val(JSON.stringify(toJSON())).change();
		}
		
		function toJSON(){
		  var items = new Array();
		  for(i=0; i<inserted.length; i++){
		    item = new Object();
		    item[valueField] = inserted[i][valueField];
		    item[displayField] = inserted[i][displayField];
		    items.push(item);
		  }
		  return items;
		}

		function updateTagInputWidth() {
			/*
			 * To make tag wrapping behave as expected, dynamically adjust
			 * the tag input's width to its content's width
			 * The best way to get the content's width in pixels is to add it
			 * to the DOM, grab the width, then remove it from the DOM.
			 */
			var temp = $("<span />").text(tagInput.val()).appendTo(inputItem);
			var width = temp.width();
			temp.remove();
			tagInput.width(width + 20);
		}

		function checkForItem(value) {
			if (currentItem != null) {
				addItem(lookup(currentItem));
			} else if (allowNewTags) {
				var object = lookup(tagInput.val());
				if (object != null) {
					addItem(object);
				}
			}
		}

		function addItem(object) {
			if (allowNewTags) {
				inserted.push(object);
				inputItem.before("<li class='superblyTagItem'><span>" + object[displayField] + "</span><a> x</a></li>");
				tagInput.val("");
				currentValue = null;
				currentItem = null;
				// add remove click event
				var new_index = tagList.children('.superblyTagItem').size() - 1;
				$(tagList.children('.superblyTagItem')[new_index]).children('a').click(function(e) {
					var value = $($(this).parent('.superblyTagItem').children('span')[0]).text();
					removeItem(lookupInserted(value));
				});
			}
			hide();
			updateTagInputWidth();
			tagInput.focus();
			setValue();
		}

		function hide() {
			suggestList.css('display', 'none');
		}

		function isInserted(object) {
			for (key in inserted) {
				if (inserted[key][valueField] == object[valueField]) {
					return true;
				}
			}
			return false;
		}
		
		function lookupInserted(value){
		  for(i=0; i<inserted.length; i++){
		    if(inserted[i][displayField] == value){
		      return inserted[i];
		    }
		  }
		  return null;
		}

		function lookup(value) {
			for (i=0; i<suggestionList.length; i++) {
				if (suggestionList[i][displayField] == value) {
					return suggestionList[i];
				}
			}
			return null;
		}

		function getIndex(object) {
			var result = -1;
			for (key in inserted) {
				if (inserted[key][valueField] == object[valueField]) {
					result = key;
					break;
				}
			}
			return result;
		}

		function removeItem(object) {
			var index = getIndex(object);
			if (index > -1) {
				inserted.splice(index, 1);
				tagList.children(".superblyTagItem").filter(function() {
					return $('span', this).html() == object[displayField];
				}).remove();
			}
			tagInput.focus();
			setValue();
		}

		function removeLastItem() {
			var last_index = inserted.length - 1;
			var object = inserted[last_index];
			removeItem(object);
		}
		
		function showLocalProxy(value){
		   var result = new Array();
		   for (var i = 0; i < suggestionList.length; i++){
		     if (suggestionList[i][displayField].substring(0, value.length).toLowerCase() == value.toLowerCase()){
		       result.push(suggestionList[i]);
		     }
		   }
		   show(result);
		}
		
		function showRemoteProxy(value){
		  var url = proxy.substring(proxy.length - 1) == "/" ? proxy.substring(0, proxy.length - 1) : proxy;
      $.get(url + "?" + displayField + "=" + value.substring(0, minChar), function(sites) {
        isProxyLoaded = true;
        suggestionList = $.map(sites, function(site) {
          return site;
        });
        // in case user typing fast key up event not response immediately
        if (value.length == minChar) show(suggestionList);
        else showLocalProxy(value);
      });
		}
		
		function showSuggestionList(value){
		  if(!isProxyLoaded){
		    showRemoteProxy(value);
		  }else{
		    showLocalProxy(value);
		  }
		}
		
		function show(list){
			for (var i = 0; i < list.length; i++) {
				if (!isInserted(list[i])) {
					suggestList.append("<li class='superblySuggestItem'>" + list[i][displayField] + "</li>");
				}
			}

			var suggestionItems = suggestList.children('.superblySuggestItem');

			// add click event to suggest items
			suggestionItems.click(function(e) {
				addItem(lookup($(this).html()));
			});

			selectedIndex = null;
			if (!allowNewTags) {
				selectedIndex = 0;
				$(suggestionItems[selectedIndex]).addClass("selected");
				currentItem = $(suggestionItems[selectedIndex]).html();
			}
		}

		function suggest(value) {
			if (value.length < minChar) {
			  currentValue = value;
			  isProxyLoaded = false;
			  // clear proxy dataset
			  suggestionList = [];
				return false;
			}

			if (value == currentValue) {
				return false;
			}else{
				suggestList.show();
			}
			
			if (value.length >= minChar) {
			  currentValue = value;
        suggestList.empty();
			  showSuggestionList(value);
			}
		}

		function selectDown() {
			var suggestions = suggestList.children('.superblySuggestItem');
			var size = suggestions.size();
			if (selectedIndex == null) {
				selectedIndex = 0;
			} else if (selectedIndex < size - 1) {
				$(suggestions[selectedIndex]).removeClass("selected");
				selectedIndex++;
			}
			$(suggestions[selectedIndex]).addClass("selected");
			currentItem = $(suggestions[selectedIndex]).html();
		}

		function selectUp() {
			if (selectedIndex > 0) {
				var suggestions = suggestList.children('.superblySuggestItem');
				$(suggestions[selectedIndex]).removeClass("selected");
				selectedIndex--;
				$(suggestions[selectedIndex]).addClass("selected");
				currentItem = $(suggestions[selectedIndex]).html();
			}
		}

	}

})(jQuery);
