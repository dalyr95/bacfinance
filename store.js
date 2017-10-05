function store() {
	riot.observable(this);

	this.store = {};

	this.on('init', function() {
		this.trigger('update_state', this.state);
		this.trigger('update_emails', this.emails);
	}.bind(this));



    var xhr = new XMLHttpRequest();

    xhr.addEventListener('load', function(data) {
    	this.originalState 	= data.currentTarget.responseText;
        this.state 			= JSON.parse(data.currentTarget.responseText);

        this.trigger('update_state', this.state);
    }.bind(this));

    xhr.open('GET', 'bac-form.json', true);
    xhr.send();

    var xhr = new XMLHttpRequest();

    xhr.addEventListener('load', function(data) {
        this.emails = JSON.parse(data.currentTarget.responseText);
        this.trigger('update_emails', this.emails);
    }.bind(this));

    xhr.open('GET', 'bac-emails.json', true);
    xhr.send();



    this.on('getState', function() {
    	this.trigger('returnState', this.state);
    }.bind(this));



    this.on('onchange', function(name, e) {
		var value 	= e.currentTarget.value;

		var job = function(obj) {
			if (obj.bacname === name) {
				if (obj.autocapitalize === true) {
					value = value.toUpperCase();
				}

				if (obj.type === 'tel') {
					value = value.replace(/\+\s*44\s*/, '0');
				}

				obj.value = value; 

				if (obj.type === 'email' && obj.datalist && value.search('@') > -1) {
					var snap = value.split('@');
					var firstPart = snap[0];
					var lastPart = snap[1];

					if (lastPart.length > 0) {
						obj.datalist.values = this.emails.map(function(v) {
							return firstPart + '@' + v;
						});
					} else {
						obj.datalist.values = [];
					}
				}
			}

			return obj;
		}.bind(this);

		this.state.forEach(function(obj) {
			if (obj.title) {
				obj.values.forEach(function(object) {
					obj = job(object);
				});
			} else {
				obj = job(obj);
			}
		}.bind(this));

		this.trigger('update_state', this.state);
	}.bind(this));



	this.on('checkboxOnChange', function(e) {
		var job = function(obj) {
			if (obj.name === e.currentTarget.name) { obj.value = e.currentTarget.checked; }
		};
		this.state.forEach(function(obj) {
			if (obj.title) {
				obj.values.forEach(function(object) {
					obj = job(object);
				});
			} else {
				obj = job(obj);
			}
		});

		this.trigger('update_state', this.state);
	}.bind(this));



	this.on('foundAddress', function(value, field, e) {

		/* AUSTIN CODE */
		var isNumeric = function(number) {
		    var dependents = /^\d*$/;
		    if ((number.match(dependents))) {
		        return true;
		    } else {
		        return false;
		    }
		}

		var companyLookup = /employments/.test(field);

		var addressParts = value.addressOrig.split(',');
		var add0 = addressParts[0].trim();
		var add1 = addressParts[1].trim();
		var add2 = addressParts[2].trim();
		var add3 = addressParts[3].trim();

		var employer = '',
		    houseName = '',
		    houseNumber = '',
		    street = '',
		    summaryDesc = '';



		if (add3 != '') {
		    street = add3;
		    if (companyLookup) {
		        employer = add0;
		        houseName = add1 + ', ' + add2;
		    } else {
		        houseName = add0 + ', ' + add1 + ', ' + add2;
		    }
		    summaryDesc = add0 + ', ' + add1 + ', ' + add2 + ', ' + add3;
		} else if (add2 != '') {
		    street = add2;
		    if (companyLookup) {
		        employer = add0;
		        houseName = add1;
		    } else {
		        houseName = add0 + ', ' + add1;
		    }
		    summaryDesc = add0 + ', ' + add1 + ', ' + add2;
		} else if (add1 != '') {
		    street = add1;
		    if (companyLookup) {
		        employer = add0;
		    } else {
		        houseName = add0;
		    }
		    summaryDesc = add0 + ', ' + add1;
		} else if (add0 != '') {
		    //if only one postcode item, is it street or houseName. We chose by houseNumber being present
		    if (isNumeric(add0.charAt(0))) {
		        street = add0;
		    } else if (companyLookup) {
		        employer = add0;
		    } else {
		        houseName = add0;
		    }
		    summaryDesc = add0;
		}

		var index = street.indexOf(' ');
		var tempHouseNumber = street.substring(0, index).trim();
		var tempStreet = street.substring(index).trim();

		if (isNumeric(tempHouseNumber.charAt(0))) {
		    street = tempStreet;
		    houseNumber = tempHouseNumber;
		}

		var district = addressParts[4].trim();
		var town = addressParts[5].trim();
		var county = addressParts[6].trim();

		if (district != '') {
		    summaryDesc = summaryDesc + ', ' + district;
		}
		if (town != '') {
		    summaryDesc = summaryDesc + ', ' + town;
		}
		if (county != '') {
		    summaryDesc = summaryDesc + ', ' + county;
		}
		/* END AUSTIN CODE */

	    var addressObject = {
			'employer': employer,
		    'houseName': houseName,
		    'houseNumber': houseNumber,
		    'district': district,
		    'town': town,
		    'street': street,
		    'summaryDesc': summaryDesc,
		    'county': county    	
	    }

		var val;

		var field = this.state.forEach(function(v) {
			if (v.title) {
				v.values.forEach(function(vv) {
					if (field === vv.bacname) { val = vv; }
				});
			} else {
				if (field === v.bacname) { val = v; }
			}
		});

		field = val;

		field.findAddress.addresses = [];

		var keys = Object.keys(field.findAddress.fields);

		keys.forEach(function(key) {
			this.state.forEach(function(obj) {
				if (obj.title) {
					obj.values.forEach(function(obj1) {
						if (obj1.bacname === key) {
							obj1.value = addressObject[field.findAddress.fields[key]];
						}
					});
				} else {
					if (obj.bacname === key) {
						obj.value = addressObject[field.findAddress.fields[key]];
					}
				}
			});
		}.bind(this));

		this.trigger('update_state', this.state);

	}.bind(this));



	this.on('resetAddressList', function() {
		this.state.forEach(function(value) {
			if (value.title) {
				value.values.forEach(function(value1) {
					if (value1.findAddress) { value1.findAddress.addresses = []; }
				});
			} else {
				if (value.findAddress) { value.findAddress.addresses = []; }
			}
		});

		this.trigger('update_state', this.state);
	}.bind(this));



	this.on('updateProgress', function() {
		console.log('updateProgress');
		var total = 0;
		var green = 0;

		this.state.forEach(function(v) {
			if (v.title) {
				v.values.forEach(function(value) {
					total++;
					if (!value.value || value.value.length === 0) { green++; }
				}.bind(this));
			}
		});

		var left = parseInt(green/total*100, 10);
		var progress = 100 - left;
		console.log(progress);
		this.trigger('update_progress', progress);
	}.bind(this));



	this.on('checkMultiples', function(title) {
		var months = 0;
		var monthsNeedsAction = false;
		var repeats = 0;

		var updateSectionAfter;

		this.state.forEach(function(v, i) {
			if (v.title && v.title === title && v.multiple) {

				v.values.forEach(function(value) {
					if (value.value && /[a-z]*Years/.test(value.name)) {
						months += parseInt(value.value, 10) * 12;
					}
					if (value.value && /[a-z]*Months/.test(value.name)) {
						months += parseInt(value.value, 10);
					}
				});

				updateSectionAfter = i;
				repeats++;

				monthsNeedsAction = true;
			}
		});

		console.log(title, months, monthsNeedsAction);
		if (monthsNeedsAction === false && months >= 36) {
			console.log('proceed');
		} else {
			var originalState = JSON.parse(this.originalState);

			var addSection;

			originalState.forEach(function(v) {
				if (v.title && v.title === title && v.multiple) {
					v.collapsed = false;
					v.displayTitle = 'Previous ' + title + ' ' + repeats;
					v.values.forEach(function(value) {
						value.bacname = value.bacname.replace(/\[[0-9]*\]/, '[' + repeats + ']');
					});

					addSection = JSON.stringify(v);
					console.log(v);
				}
			});

			this.state.splice(updateSectionAfter + 1, 0, JSON.parse(addSection));

			this.trigger('multiplePass');
		}
	}.bind(this));
}