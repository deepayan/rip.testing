// Adapted from https://github.com/kavyasukumar/imgSlider, available under
//
// The MIT License (MIT)
//
// Copyright (c) 2015 Kavya Sukumar
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


(function ($) {
    'use strict';
    $.fn.slider = function (options) {

	//default options
	var settings = $.extend($.fn.slider.defaultOptions, options);

	// NOTE: initialization delegated to setSliderWidth() in
	// filenames.js. Consider moving the rest too eventually; we
	// are basically setting some event handlers.

	var startY; // to keep track of vertical scroll for touch

	var init = function () {
	    var $this = $(this);
	    // var width = 200;
	    // var width = settings.sliderWidth; // $this.width();
	    // $this.css('width' , width + 'px');
	    // $this.find('.image img').css('width' , width + 'px');
	    // $this.find('.left.image').css('width' , Math.floor(width * settings.initialPosition));

	    // if (settings.showInstruction) {
	    // 	// Check if instruction div exists before adding
	    // 	var $instrDiv = null;
	    // 	$instrDiv = $('div.instruction');

	    // 	if ($instrDiv.length === 0) {
	    // 	    $instrDiv = $('<div></div>')
	    // 		.addClass('instruction')
	    // 		.append('<p></p>');
	    // 	    $this.append($instrDiv);
	    // 	}

	    // 	$instrDiv.children('p')
	    // 	    .text(settings.instructionText);

	    // 	//set left offset of instruction
	    // 	$instrDiv.css('left', (settings.initialPosition - $instrDiv.children('p').width() / (2 * width)) * 100 + '%');
	    // }
	};

	var slideResize = function (e) {
	    e.preventDefault();
	    //hide instructions
	    // FIXME: uncomment if we show instructions in the first place
	    // $(e.currentTarget).children('.instruction').hide();
	    var width;
	    if (e.type.startsWith('touch')){
		width = e.originalEvent.touches[0].clientX - e.currentTarget.offsetLeft;
		// width = e.originalEvent.touches[0].clientX - e.originalEvent.touches[0].target.offsetLeft; WRONG
		// if a touch move event, then we also want to scroll vertically
		if (e.type == "touchstart") startY = e.originalEvent.touches[0].clientY;
		if (e.type == "touchmove")
		{
		    var currentY = e.originalEvent.touches[0].clientY;
		    window.scrollBy(0, startY - currentY);
		    startY = currentY;
		}
		
	    } else {
		width = e.offsetX === undefined ? e.pageX - e.originalEvent.layerX : e.offsetX;
	    }
	    if (width<=$(this).width()){
		$(this).find('.left.image').css('width', width + 'px');
	    }
	};

	var enableSliderDrag = function (e) {
	    e.preventDefault();
	    $(this).css('cursor' , 'ew-resize')
		.on('mousemove.sliderns', slideResize)
		.on('touchmove.sliderns', slideResize);
	};

	var disableSliderDrag = function (e) {
	    e.preventDefault();
	    $(this).css('cursor', 'normal')
		.off('mousemove.sliderns')
		.off('touchmove.sliderns');
	};

	var redrawSlider = function () {
	    return $('.slider.responsive').each(init);
	};

	$(window).on('resize', redrawSlider);
	return this.each(init)
	    .on('click touchstart', slideResize)
	    .on('mousedown touchstart', enableSliderDrag)
	    .on('mouseup touchend', disableSliderDrag);
    };

    $.fn.slider.defaultOptions= {
	// sliderWidth: 1000,
	initialPosition: 0.5,
	showInstruction: true,
	instructionText: 'Click and Drag'
    };

}(jQuery));
