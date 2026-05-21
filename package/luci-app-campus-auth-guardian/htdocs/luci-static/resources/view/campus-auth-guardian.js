'use strict';
'require view';
'require form';
'require fs';
'require ui';

return view.extend({
	render: function() {
		var m, s, o;

		m = new form.Map('campus-auth-guardian', _('Campus Auth Guardian'),
			_('Campus portal authentication and guardian service.'));

		s = m.section(form.TypedSection, 'main', _('Settings'));
		s.anonymous = true;

		o = s.option(form.Flag, 'enabled', _('Enable service'));
		o.default = '0';

		o = s.option(form.Flag, 'guardian_enabled', _('Guardian mode'));
		o.default = '0';

		o = s.option(form.Value, 'auth_url', _('Auth URL'));
		o.placeholder = 'http://10.10.102.50:801/eportal/portal/login';
		o.rmempty = false;

		o = s.option(form.Value, 'check_url', _('Check URL'));
		o.placeholder = 'http://10.10.102.50:801/eportal/portal/online_list?user_account=&user_password=123&wlan_user_mac=000000000000&wlan_user_ip=';
		o.rmempty = false;

		o = s.option(form.Value, 'student_id', _('Student ID'));
		o.rmempty = false;

		o = s.option(form.ListValue, 'operator_type', _('Operator'));
		o.value('campus', _('Campus'));
		o.value('cmcc', _('China Mobile'));
		o.value('unicom', _('China Unicom'));
		o.value('telecom', _('China Telecom'));
		o.default = 'unicom';

		o = s.option(form.Value, 'user_password', _('Password'));
		o.password = true;
		o.rmempty = false;

		o = s.option(form.Value, 'fixed_ip', _('Fixed IP'));
		o.placeholder = _('Leave empty to send blank wlan_user_ip');

		o = s.option(form.Value, 'retry_interval', _('Retry interval'));
		o.datatype = 'uinteger';
		o.default = '10';

		o = s.option(form.Value, 'max_retries', _('Max retries'));
		o.datatype = 'uinteger';
		o.default = '3';

		o = s.option(form.Value, 'check_interval', _('Check interval'));
		o.datatype = 'uinteger';
		o.default = '30';

		s = m.section(form.TypedSection, '_actions', _('Actions'));
		s.anonymous = true;
		s.render = function() {
			return E('div', { 'class': 'cbi-section' }, [
				E('h3', {}, _('Actions')),
				E('p', {}, _('Run helper commands without leaving this page.')),
				E('button', {
					'class': 'btn cbi-button cbi-button-apply',
					'click': ui.createHandlerFn(this, function() {
						return fs.exec('/usr/bin/campus-auth-guardian.sh', [ 'auth' ])
							.then(function() { ui.addNotification(null, E('p', _('Authentication command finished.'))); })
							.catch(function(e) { ui.addNotification(null, E('p', _('Authentication failed: ') + e.message)); });
					})
				}, _('Authenticate now')),
				' ',
				E('button', {
					'class': 'btn cbi-button cbi-button-action',
					'click': ui.createHandlerFn(this, function() {
						return fs.exec('/usr/bin/campus-auth-guardian.sh', [ 'check' ])
							.then(function() { ui.addNotification(null, E('p', _('Network is connected.'))); })
							.catch(function() { ui.addNotification(null, E('p', _('Network check did not report connected.'))); });
					})
				}, _('Check status')),
				' ',
				E('button', {
					'class': 'btn cbi-button cbi-button-reload',
					'click': ui.createHandlerFn(this, function() {
						return fs.exec('/etc/init.d/campus-auth-guardian', [ 'restart' ])
							.then(function() { ui.addNotification(null, E('p', _('Service restarted.'))); })
							.catch(function(e) { ui.addNotification(null, E('p', _('Restart failed: ') + e.message)); });
					})
				}, _('Restart service'))
			]);
		};

		return m.render();
	}
});
