<bac-form-raw>
  <span></span>
  this.root.innerHTML = this.opts.content;
</bac-form-raw>

<bac-form-input class={ finance_half: value.half }>
	<label>
		{ value.label || value.placeholder } / { value.value }
		<input if={ value.type !== 'select' && value.type !== 'checkbox' && value.type !== 'html' } class={ empty: (value.value.length === 0), findAddress: value.findAddress } type={ value.type } name={ value.name } value={ value.value } autocomplete={ value.autocomplete } placeholder={ value.placeholder } pattern={ value.pattern } min={ value.min } max={ value.max } list={ value.datalist && value.datalist.id } maxlength={ value.limit } required={ value.required !== false } autocapitalize={ (value.autocapitalize) ? 'characters' : false } oninput={ onchange.bind(this, value.bacname) } onblur={ this.inputBlur }/>
		<datalist if={ value.datalist } id={ value.datalist.id }>
			<option each={ v, i in value.datalist.values } value={ v } />
		</datalist>
		<button if={ value.findAddress } class="findAddress" disabled={ value.value.length === 0 } onclick={ findAddress.bind(this, value.bacname) }>Find Address</button>

		<input if={ value.type === 'checkbox' } class={ empty: (value.value.length === 0) } type="checkbox" checked={ (value.value === true) } name={ value.name } autocomplete={ value.autocomplete } placeholder={ value.placeholder } pattern={ value.pattern } required={ value.required !== false } onchange={ checkboxOnChange }/>

		<select if={ value.type === 'select' } class={ empty: (value.value.length === 0) } name={ value.name } onchange={ onchange.bind(this, value.bacname) } required>
			<option each={ value.values } value={ value } disabled={ disabled } selected={ selected }>{ label }</option>
		</select>

		<div if={ value.type === 'html' }>
			<bac-form-raw content={ value.value }>/<bac-form-raw>
		</div>

		<div class="finance_tooltip" if={ value.tooltip } data-value={ value.tooltip }>?</div>

		<ul if={ value.findAddress && value.findAddress.addresses.length > 0} class="address_dropdown">
			<li each={ address, i in value.findAddress.addresses } onclick={ foundAddress.bind(this, address, value.bacname) }>{ address.addressString }</li>
		</ul>
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
				if (e.currentTarget.checkValidity() === true) {
					RiotControl.trigger('updateProgress');
				}
				var $focusEl = e.currentTarget.parentNode.parentNode.nextElementSibling.querySelector('input');
				if ($focusEl) { $focusEl.focus(); }
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

	            		obj.addressString 	= a.join(',');
	            		obj.addressObject 	= addressObject;
	            		obj.addressOrig 	= address;

	            		return obj;
	            	});

	                value.findAddress.addresses = data;

	                document.addEventListener('click', this.removeOverlays, {
	                	passive: true,
	                	once: true
	                });

	                this.update();
	            }.bind(this));

	            xhr.open('GET', 'https://api.getaddress.io/v2/uk/' + value.value.trim() + '?api-key=Q2iEgiL-hkCppww2KdarRg3675', true);
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

		this.inputBlur = function(e) {
			if (e.currentTarget.checkValidity() === true) {
				RiotControl.trigger('updateProgress');
			}
		}
	</script>
</bac-form-input>

<bac-form>
	<div class="container" if={ state }>
		<div class="finance_progress">
			<div>
				<span style="left: calc({ this.progress }% - 8px);"></span>
				<em style="width: calc({ this.progress }% - 8px);"></em>
			</div>
		</div>
		<form>
			<virtual each={ value, i in state }>
				<div if={ value.title } class={ collapsed: value.collapsed, finance_section: true }>
					<h2>{ value.displayTitle || value.title }</h2>
					<virtual each={ value1, i1 in value.values }>
						<bac-form-input value={ value1 } i={ i1 }></bac-form-input>
					</virtual>
					<button onclick={ nextStep.bind(this, value.title) }>Next</button>
				</div>
				<virtual if={ !value.title }>
					<bac-form-input value={ value } i={ i }></bac-form-input>
				</virtual>
			</virtual>
		</form>

		<div class="finance_modal" if={ this.modalDisplay === true } onclick={ closeFinanceModal }>
			<div class="finance_modal_content">
				<div class="finance_modal_close">&times;</div>
				<h3>Data Protection Act</h3>
				Credit reference searches will be conducted by the lenders in order to establish your credit worthiness. On occasions we will have to try more than one lender from our panel to obtain a credit acceptance which may result in several credit searches being registered. Additional information may be required and lenders may on occasions contact employers as part of their checks. Alternative terms may be offered.
				Non payment of credit agreements and default will severely affect your credit rating and may result with the agreement vehicle being repossessed by the lender and or action being taken via the County Courts. The way you conduct your agreement is registered with all the Credit Reference Agencies and therefore any default could severely affect your chances of being accepted for credit in the future.
				If you are taking out a Hire Purchase, Lease Purchase or Personal Loan agreement with a Balloon Payment at the end, please be aware that the Balloon (Residual value) is NOT GUARANTEED by the lender and is your responsibility to pay. If you require the protection of a Minimum Guaranteed Future Value you will need a PCP (Personal Contract Purchase) agreement.<br/>
				Alternative (Direct) sources of finance are available to you i.e. Banks or via internet aggregators.<br/>
				By agreeing below, you acknowledge that as part of the process of obtaining finance for your vehicle we will need to pass your details on to one or more of our finance partners A list of these partners together with their consumer credit licence numbers are available on request. You also acknowledge that any organisation approached for credit will need to undertake credit searches with a credit reference agency which may affect your credit rating.
			</div>
		</div>
	</div>

	<script>
		window.tag = this;

		this.progress = 0;
		this.modalDisplay = false;

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

		RiotControl.on('update_progress', function(progress) {
			var update = (progress !== this.progress);
			this.progress = progress;
			if (update) { this.update(); }
		}.bind(this));



		this.nextStep = function(title, e) {
			e.preventDefault();

			var currentTarget = e.currentTarget;

			var fails = [];
			[].slice.call(currentTarget.parentNode.querySelectorAll('input[required], select[required]')).forEach(function(input) {
				if (input.checkValidity() === false) { fails.push(input); }
			});

			if (fails.length > 0) {
				fails.forEach(function($fail) {
					$fail.classList.remove('empty');
					$fail.classList.add('finance_fail');
				});
			} else {
				RiotControl.one('multiplePass', function() {
					console.log(12345);
					var $nextStep = currentTarget.parentNode.nextElementSibling;

					if ($nextStep) { $nextStep.classList.remove('collapsed'); }
				});
				RiotControl.trigger('checkMultiples', title);
			}
		}.bind(this);



		this.financeModal = function(e) {
			this.modalDisplay = true;
			this.update();
		}

		this.closeFinanceModal = function(e) {
			console.log(e.target);
			if (!e.target.classList.contains('finance_modal_content')) {
				this.modalDisplay = false;
			}
		}
	</script>

	<style>
		.container {
			border-left: 1px solid #ccc;
			border-right: 1px solid #ccc;
			margin: 0 auto;
			max-width: 100vw;
			min-height: 100vh;
			padding: 62px 0 10px;
			width: 640px;
		}

		div.collapsed {
			overflow: hidden;
			height: 58px;
		}

		.finance_section {
			padding: 10px;
		}

		h2 {
			background-color: #f40057;
			color: #fff;
			padding: 10px;
			margin: 0 -10px 10px;
			width: calc(100% + 20px);
		}

		label {
			display: block;
			margin-top: 5px;
			margin-bottom: 10px;
			position: relative;
			min-height: 40px;
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

		input:not(.empty):not(:focus):valid,
		select:not(.empty):not(:focus):valid  {
			border-color: #43e97b;
		}

		input:not(.empty):not(:focus):invalid,
		select:not(.empty):not(:focus):invalid {
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

		.finance_tooltip {
			background-color: #ccc;
			border-radius: 100%;
			bottom: 5px;
			color: #fff;
			height: 30px;
			line-height: 30px;
			position: absolute;
			right: 10px;
			text-align: center;
			width: 30px;
		}

		.finance_tooltip:hover:before {
			background-color: #ccc;
			content: '';
			display: block;
			height: 10px;
			width: 10px;
			transform: rotate(45deg) translate(-50%);
			position: absolute;
			top: -12px;
			left: 50%;
			pointer-events: none;
		}

		.finance_tooltip:hover:after {
			content: attr(data-value);
			padding: 10px;
			background-color: #ccc;
			display: block;
			width: 200px;
			position: absolute;
			left: 50%;
			bottom:  40px;
			transform: translate3d(-50%, 0, 0);
			z-index: 2;
			pointer-events: none;
		}

		button + .finance_tooltip {
			right: 110px;
		}

		@media (max-width: 800px) {
			.finance_tooltip:hover:after {
				transform: translate3d(-85%, 0, 0);
			}
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

		.finance_fail:invalid {
			animation-duration: 1s;
			animation-name: finance_fail;
			transform: translate3d(0, 0, 0);
		}

		@keyframes finance_fail {
			from {
				box-shadow: 0 0 0 0 orange;
			}
			50% {
				box-shadow: 0 0 5px 0px orange;
			}
			to {
				box-shadow: 0 0 0 0 orange;
			}
		}

		.finance_half {
			float: left;
			width: calc(50% - 20px);
		}

		.finance_half + .finance_half {
			float: right;
		}

		.finance_progress {
			-webkit-backdrop-filter: blur(2px);
			backdrop-filter: blur(2px);
			background-color: rgba(255,255,255,0.9);
			border-bottom: 1px solid #ccc;
			height: 52px;
			position: fixed;
			top:  0;
			width: 100%;
			left: 0;
			z-index: 1;
		}

		.finance_progress div {
			background-color: #ccc;
			height: 2px;
			position: relative;
			width: 75vw;
			margin: 25px auto;
		}

		.finance_progress div span {
			background-color: #43e97b;
			height: 16px;
			width: 16px;
			border-radius: 100%;
			position: absolute;
			left: 0;
			top: -7px;
			transform: translate3d(0, 0, 0);
			transition: left 0.2s linear;
			box-shadow: 0 1px 2px 0 rgba(0,0,0,0.6);
		}

		.finance_progress div em {
			background-color: #43e97b;
			display: block;
			left: 0;
			position: absolute;
			top: 0;
			width: 0;
		    height: 2px;
		    transition: width 0.2s linear;

		}

		.finance_modal {
			cursor: pointer;
			background-color: blue;
			height: 100%;
			position: fixed;
			top: 0;
			width: 100%;
			z-index: 20;
			left: 0;
		}

		.finance_modal_content {
			cursor: default;
			background-color: #fff;
			padding: 20px;
			left:  50%;
			max-width: 640px;
			position: fixed;
			top: 50%;
			transform: translate3d(-50%, -50%, 0);
			width: 95vw;
			max-height: 100vh;
			overflow-y: scroll;
			-webkit-overflow-scrolling: touch;
		}

		.finance_modal_close {
			cursor: pointer;
			height: 40px;
			line-height: 40px;
			position: absolute;
			text-align: center;
			width: 40px;
			top: 0;
			right: 0;
		}

	</style>
</bac-form>