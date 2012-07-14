window.arrayDiff = function(array1, array2) {
    return array1.filter(function(i) {return !(array2.indexOf(i) > -1);});
};
