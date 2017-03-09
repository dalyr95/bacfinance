<bac-form>
	<div class="container" if={ state }>
		<form>
			<virtual each={ value, i in state }>
				<label>
					{ value.label || value.placeholder } / { value.value }
					<input if={ value.type !== 'select' && value.type !== 'checkbox' } class={ empty: (value.value.length === 0) } type={ value.type } name={ value.name } value={ value.value } autocomplete={ value.autocomplete } placeholder={ value.placeholder } pattern={ value.pattern } min={ value.min } max={ value.max } list={ value.datalist && value.datalist.id } maxlength={ value.limit } required oninput={ onchange } />
					<datalist if={ value.datalist } id={ value.datalist.id }>
						<option each={ v, i in value.datalist.values } value={ v } />
					</datalist>

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

		this.onchange = function(e) {
			console.log(e.currentTarget.value);

			var value 	= e.currentTarget.value;
			var name 	= e.currentTarget.name;

			this.state.forEach(function(obj) {
				if (obj.name === name) {
					obj.value = value; 

					if (obj.type === 'email' && obj.datalist && value.search('@') > -1) {
						var firstPart = value.split('@')[0];

						obj.datalist.values = this.emails.map(function(v) {
							return firstPart + '@' + v;
						}).slice(0,5);
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

		input:not(.empty):valid {
			border-color: green;
		}

		input:not(.empty):invalid {
			border-color: orange;
		}
	</style>
</bac-form>