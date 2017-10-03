<bac-form-input>
	<label>
		{ value.label || value.placeholder } / { value.value }
		<input if={ value.type !== 'select' && value.type !== 'checkbox' } class={ empty: (value.value.length === 0), findAddress: value.findAddress } type={ value.type } name={ value.name } value={ value.value } autocomplete={ value.autocomplete } placeholder={ value.placeholder } pattern={ value.pattern } min={ value.min } max={ value.max } list={ value.datalist && value.datalist.id } maxlength={ value.limit } required autocapitalize={ (value.autocapitalize) ? 'characters' : false } oninput={ onchange.bind(this, value.bacname) } />
		<datalist if={ value.datalist } id={ value.datalist.id }>
			<option each={ v, i in value.datalist.values } value={ v } />
		</datalist>
		<button if={ value.findAddress } class="findAddress" disabled={ value.value.length === 0 } onclick={ findAddress.bind(this, value.bacname) }>Find Address</button>

		<ul if={ value.findAddress && value.findAddress.addresses.length > 0} class="address_dropdown">
			<li each={ address, i in value.findAddress.addresses } onclick={ foundAddress.bind(this, address, value.bacname) }>{ address.addressString }</li>
		</ul>

		<input if={ value.type === 'checkbox' } class={ empty: (value.value.length === 0) } type="checkbox" checked={ (value.value === true) } name={ value.name } autocomplete={ value.autocomplete } placeholder={ value.placeholder } pattern={ value.pattern } required onchange={ checkboxOnChange }/>

		<select if={ value.type === 'select' } name={ value.name } onchange={ onchange.bind(this, value.bacname) }>
			<option each={ value.values } value={ value } disabled={ disabled } selected={ selected } required>{ label }</option>
		</select>
	</label>


	<script>
		var mapRefs = function() {
			this.value = this.opts.riotValue;
			this.i = this.opts.i;
		}.bind(this);

		mapRefs();

		this.on('update', mapRefs);

		this.onchange = function(name, e) {
			RiotControl.trigger('onchange', name, e);

			if (e.currentTarget.tagName === 'SELECT') {
				e.currentTarget.parentNode.parentNode.nextElementSibling.querySelector('input').focus();
			}
		}

		this.checkboxOnChange = function(e) {
			RiotControl.trigger('checkboxOnChange', e);
		}

		this.findAddress = function(value, e) {
			e.preventDefault();

			var state;

			var job = function(state) {
				var values = [];

				state.forEach(function(v) {
					if (v.title) {
						v.values.forEach(function(vv) {
							if (vv.bacname === value) { values.push(vv); }
						});
					} else {
						if (v.bacname === value) { values.push(v); }
					}
				});

				value = values[0];

	            var xhr = new XMLHttpRequest();

	            xhr.addEventListener('load', function(data) {
	            	var keys = 'Line1,Line2,Line3,Line4,Locality,Town/City,County'.split(',');

	            	var data = JSON.parse(data.currentTarget.responseText);

	            	if (!data.Addresses) { alert('Sorry, couldn\'t find an address for "' + value.value + '".'); return; }

	            	data = data.Addresses.map(function(address) {
	            		var obj = {};
	            		var addressObject = {};

	            		var a = address.split(',');
	            		a = a.filter(function(v, index) {
	            			v = v.trim();
	            			addressObject[keys[index].toLowerCase()] = v;
	            			return (v.length > 0);
	            		});

	            		obj.addressString = a.join(',');
	            		obj.addressObject = addressObject;

	            		return obj;
	            	});

	                value.findAddress.addresses = data;

	                document.addEventListener('click', this.removeOverlays, {
	                	passive: true,
	                	once: true
	                });

	                this.update();
	            }.bind(this));

	            xhr.open('GET', 'https://api.getaddress.io/v2/uk/' + value.value + '?api-key=Q2iEgiL-hkCppww2KdarRg3675', true);
	            xhr.send();
	        }.bind(this);


			RiotControl.one('returnState', function(state) {
				console.log(state);
				job(state);
			});
			RiotControl.trigger('getState');
		}

		this.foundAddress = function(value, field, e) {
			RiotControl.trigger('foundAddress', value, field, e);
			document.removeEventListener('click', this.removeOverlays, {
            	passive: true,
            	once: true
            });
		}

		this.removeOverlays = function(e) {
			if (this.root.querySelector('.findAddress').contains(e.currentTarget) === false) {
				RiotControl.trigger('resetAddressList');
			}

			document.removeEventListener('click', this.removeOverlays, {
            	passive: true,
            	once: true
            });
		}.bind(this);
	</script>
</bac-form-input>

<bac-form>
	<div class="container" if={ state }>
		<form>
			<virtual each={ value, i in state }>
				<div if={ value.title } class={ collapsed: value.collapsed }>
					<h2>{ value.title }</h2>
					<virtual each={ value1, i1 in value.values }>
						<bac-form-input value={ value1 } i={ i1 }></bac-form-input>
					</virtual>
				</div>
				<virtual if={ !value.title }>
					<bac-form-input value={ value } i={ i }></bac-form-input>
				</virtual>
			</virtual>
		</form>
	</div>

	<script>
		window.tag = this;

		this.on('before-mount', function() {
			RiotControl.trigger('init');
		});

		RiotControl.on('update_state', function(state) {
			this.state = state;
			this.update();
		}.bind(this));

		RiotControl.on('update_emails', function(emails) {
			this.emails = emails;
		}.bind(this));
	</script>

	<style>
		.container {
			border-left: 1px solid #ccc;
			border-right: 1px solid #ccc;
			margin: 0 auto;
			max-width: 100vw;
			min-height: 100vh;
			padding: 10px;
			width: 640px;
		}

		div.collapsed {
			overflow: hidden;
			height: 58px;
		}

		h2 {
			background-color: #f40057;
			color: #fff;
			margin: 10px -10px;
			padding: 10px;
			width: calc(100% + 20px);
		}

		label {
			display: block;
			margin-top: 5px;
			margin-bottom: 10px;
			position: relative;
		}

		select,
		input:not([type="checkbox"]) {
			display: block;
			margin: 4px 0;
			width: 100%;
			height: 40px;
			border-radius: 5px;
			padding: 2px 6px;
			border: 2px solid #ccc;
			outline: none;
			-webkit-appearance: none;
		}

		input:focus {
			border-color: #666;
		}

		input:not(.empty):not(:focus):valid {
			border-color: #43e97b;
		}

		input:not(.empty):not(:focus):invalid {
			border-color: orange;
		}

		input.findAddress {
			width: calc(100% - 100px);
		}

		button[disabled] {
			opacity: 0.5;
			pointer-events: none;
		}

		button.findAddress {
			background-color: #666;
			border-radius: 5px;
			border: none;
			bottom: 0;
			color: #fff;
			height: 40px;
			position: absolute;
			right: 0;
			width: 90px;
			-webkit-appearance: none;
		}

		.address_dropdown {
		    background: #fff;
		    border: 1px solid #ccc;
		    box-shadow: 2px 2px 2px rgba(0,0,0,0.3);
		    max-width: 100%;
		    padding: 10px;
		    position: absolute;
		    z-index: 10;
		}

		.address_dropdown li {
			border-bottom: 1px solid rgba(0,0,0,0.3);
			cursor: pointer;
			overflow: hidden;
			padding: 8px 0;
			text-overflow: ellipsis;
			white-space: nowrap;
		}

		.address_dropdown li:last-child {
			border-bottom: none;
		}
	</style>
</bac-form>