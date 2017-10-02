function store() {
	riot.observable(this);

	this.store = {};

	this.on('init', function() {
		this.trigger('update_state', this.state);
		this.trigger('update_emails', this.emails);
	}.bind(this));

    var xhr = new XMLHttpRequest();

    xhr.addEventListener('load', function(data) {
        this.state = JSON.parse(data.currentTarget.responseText);
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
    	return this.state;
    })

    this.on('onchange', function(name, e) {
		var value 	= e.currentTarget.value;

		var job = function(obj) {
			if (obj.bacname === name) {
				if (obj.autocapitalize === true) {
					value = value.toUpperCase();
				}

				obj.value = value; 

				if (obj.type === 'email' && obj.datalist && value.search('@') > -1) {
					var firstPart = value.split('@')[0];

					obj.datalist.values = this.emails.map(function(v) {
						return firstPart + '@' + v;
					}).slice(0,8);
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
}