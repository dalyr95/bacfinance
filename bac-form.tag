<bac-form>
	<div class="container" if={ state }>
		<form>
			<virtual each={ value, i in state }>
				<label>
					{ value.label || value.placeholder } / { value.value }
					<input if={ value.type !== 'select' && value.type !== 'checkbox' } class={ empty: (value.value.length === 0), findAddress: value.findAddress } type={ value.type } name={ value.name } value={ value.value } autocomplete={ value.autocomplete } placeholder={ value.placeholder } pattern={ value.pattern } min={ value.min } max={ value.max } list={ value.datalist && value.datalist.id } maxlength={ value.limit } required autocapitalize={ (value.autocapitalize) ? 'characters' : false } oninput={ onchange.bind(this, value.bacname) } />
					<datalist if={ value.datalist } id={ value.datalist.id }>
						<option each={ v, i in value.datalist.values } value={ v } />
					</datalist>
					<button if={ value.findAddress } class="findAddress" disabled={ value.value.length === 0} onclick={ findAddress.bind(this, value.bacname) }>Find Address</button>

					<ul if={ value.findAddress && value.findAddress.addresses.length > 0} class="address_dropdown">
						<li each={ address, i in value.findAddress.addresses } onclick={ foundAddress.bind(this, address, value.bacname) }>{ address.addressString }</li>
					</ul>

					<input if={ value.type === 'checkbox' } class={ empty: (value.value.length === 0) } type="checkbox" checked={ (value.value === true) } name={ value.name } autocomplete={ value.autocomplete } placeholder={ value.placeholder } pattern={ value.pattern } required onchange={ checkboxOnChange }/>

					<select if={ value.type === 'select' } name={ value.name } onchange={ onchange }>
						<option each={ value.values } value={ value } disabled={ disabled } selected={ selected } required>{ label }</option>
					</select>
				</label>
			</virtual>
		</form>
	</div>

	<script>
		window.tag = this;

		this.on('before-mount', function() {
			console.log('before-mount');
            var xhr = new XMLHttpRequest();

            xhr.addEventListener('load', function(data) {
                this.state = JSON.parse(data.currentTarget.responseText);
                this.update();
            }.bind(this));

            xhr.open('GET', 'bac-form.json', true);
            xhr.send();

            var xhr = new XMLHttpRequest();

            xhr.addEventListener('load', function(data) {
                this.emails = JSON.parse(data.currentTarget.responseText);
            }.bind(this));

            xhr.open('GET', 'bac-emails.json', true);
            xhr.send();
		});

		this.on('mount', function(e) {
			this.root.addEventListener('animationstart', function(e) {
				console.log(e);
			});
		});

		this.onchange = function(name, e) {
			console.log(e.currentTarget.value);

			var value 	= e.currentTarget.value;

			this.state.forEach(function(obj) {
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
			}.bind(this));

			if (e.currentTarget.tagName === 'SELECT') {
				e.currentTarget.parentNode.nextElementSibling.querySelector('input').focus();
			}
		}

		this.checkboxOnChange = function(e) {
			console.log(e.currentTarget.checked);

			this.state.forEach(function(obj) {
				if (obj.name === e.currentTarget.name) { obj.value = e.currentTarget.checked; }
			});
		}

		this.findAddress = function(value, e) {
			console.log(value, e);
			e.preventDefault();

			value = this.state.filter(function(v) {
				return (v.bacname === value);
			});

			value = value[0];
			console.log(value);
            var xhr = new XMLHttpRequest();

            xhr.addEventListener('load', function(data) {
            	var keys = 'Line1,Line2,Line3,Line4,Locality,Town/City,County'.split(',');
            	console.log(keys);
            	data = JSON.parse(data.currentTarget.responseText).Addresses.map(function(address) {
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

                document.addEventListener('click', this.removeOverlays);

                this.update();
            }.bind(this));

            xhr.open('GET', 'https://api.getaddress.io/v2/uk/' + value.value + '?api-key=Q2iEgiL-hkCppww2KdarRg3675', true);
            xhr.send();
		}

		this.foundAddress = function(value, field, e) {
			console.log(value, field);
			var field = this.state.filter(function(v) {
				return (field === v.bacname);
			})[0];

			field.findAddress.addresses = [];

			document.removeEventListener('click', this.removeOverlays);

			console.log(value);

			console.log(1, field);
		}

		this.removeOverlays = function(e) {
			console.log('click');

			if (this.root.querySelector('.findAddress').contains(e.currentTarget) === false) {
				this.state = this.state.map(function(value) {
					if (value.findAddress) { value.findAddress.addresses = []; }
					return value;
				});

				this.update();
			}

			document.removeEventListener('click', this.removeOverlays);
		}.bind(this);
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