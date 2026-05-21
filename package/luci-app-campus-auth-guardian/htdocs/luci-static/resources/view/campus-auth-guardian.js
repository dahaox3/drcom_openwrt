'use strict';
'require view';
'require form';
'require fs';
'require ui';
'require uci';

return view.extend({
	load: function() {
		return uci.load('campus-auth-guardian');
	},

	render: function() {
		var m, s, o, accounts, i, label;

		accounts = uci.sections('campus-auth-guardian', 'account');

		m = new form.Map('campus-auth-guardian', _('校园网认证守护'),
			_('用于校园网门户认证、在线检测和断线自动重认证。'));

		s = m.section(form.NamedSection, 'main', 'campus-auth-guardian', _('设置'));
		s.anonymous = true;

		s.tab('basic', _('基础设置'));
		s.tab('account', _('账号设置'));
		s.tab('request', _('认证请求'));
		s.tab('check', _('检测与守护'));

		o = s.taboption('basic', form.Flag, 'enabled', _('启用服务'));
		o.default = '0';

		o = s.taboption('basic', form.Flag, 'guardian_enabled', _('启用守护模式'));
		o.default = '0';

		o = s.taboption('basic', form.Value, 'auth_url', _('认证接口地址'));
		o.placeholder = 'http://10.10.102.50:801/eportal/portal/login';
		o.rmempty = false;

		o = s.taboption('basic', form.Value, 'check_url', _('在线检测接口地址'));
		o.placeholder = 'http://10.10.102.50:801/eportal/portal/online_list?user_account=&user_password=123&wlan_user_mac=000000000000&wlan_user_ip=';
		o.rmempty = false;

		o = s.taboption('account', form.ListValue, 'active_account', _('当前使用账号'));
		o.value('', _('手动填写账号'));
		for (i = 0; i < accounts.length; i++) {
			label = accounts[i].label || accounts[i].student_id || accounts[i]['.name'];
			o.value(accounts[i]['.name'], label);
		}

		o = s.taboption('account', form.Value, 'student_id', _('手动学号或账号'));

		o = s.taboption('account', form.Value, 'user_password', _('手动密码'));
		o.password = true;

		o = s.taboption('account', form.ListValue, 'operator_type', _('手动运营商'));
		o.value('campus', _('校园网'));
		o.value('cmcc', _('中国移动'));
		o.value('unicom', _('中国联通'));
		o.value('telecom', _('中国电信'));
		o.default = 'unicom';

		o = s.taboption('account', form.Value, 'operator_domain', _('手动运营商后缀'));
		o.placeholder = _('留空表示使用上面选择的运营商；填 none 表示不追加 @运营商。');

		o = s.taboption('account', form.Value, 'account_prefix', _('手动账号前缀'));
		o.placeholder = ',0,';
		o.default = ',0,';

		o = s.taboption('account', form.Value, 'fixed_ip', _('手动固定 IP'));
		o.placeholder = _('留空则 wlan_user_ip 发送为空。');

		o = s.taboption('request', form.Value, 'callback', _('回调参数 callback'));
		o.default = 'dr1005';

		o = s.taboption('request', form.Value, 'login_method', _('登录方式 login_method'));
		o.default = '1';

		o = s.taboption('request', form.Value, 'wlan_user_ipv6', _('用户 IPv6'));

		o = s.taboption('request', form.Value, 'wlan_user_mac', _('用户 MAC'));
		o.default = '000000000000';

		o = s.taboption('request', form.Value, 'wlan_ac_ip', _('AC IP'));

		o = s.taboption('request', form.Value, 'wlan_ac_name', _('AC 名称'));

		o = s.taboption('request', form.Value, 'js_version', _('JS 版本 jsVersion'));
		o.default = '4.1.3';

		o = s.taboption('request', form.Value, 'terminal_type', _('终端类型 terminal_type'));
		o.default = '1';

		o = s.taboption('request', form.Value, 'auth_version', _('请求版本 v'));
		o.default = '3015';

		o = s.taboption('request', form.Value, 'lang', _('语言 lang'));
		o.default = 'zh-cn';

		o = s.taboption('request', form.Value, 'auth_extra_params', _('额外认证参数'));
		o.placeholder = 'param1=value1&param2=value2';

		o = s.taboption('check', form.Value, 'online_keyword', _('在线成功关键词'));
		o.placeholder = _('响应中包含该文本时认为已在线。');

		o = s.taboption('check', form.Value, 'portal_keyword', _('门户页关键词'));
		o.default = 'eportal';
		o.placeholder = _('响应中包含该文本时认为进入了认证门户。');

		o = s.taboption('check', form.Value, 'retry_interval', _('重试间隔'));
		o.datatype = 'uinteger';
		o.default = '10';

		o = s.taboption('check', form.Value, 'max_retries', _('最大重试次数'));
		o.datatype = 'uinteger';
		o.default = '3';

		o = s.taboption('check', form.Value, 'check_interval', _('检测间隔'));
		o.datatype = 'uinteger';
		o.default = '30';

		s = m.section(form.GridSection, 'account', _('账号管理'));
		s.anonymous = true;
		s.addremove = true;
		s.sortable = true;

		o = s.option(form.Value, 'label', _('名称'));
		o.placeholder = _('例如：宿舍联通');

		o = s.option(form.Value, 'student_id', _('学号或账号'));
		o.rmempty = false;

		o = s.option(form.Value, 'user_password', _('密码'));
		o.password = true;
		o.rmempty = false;

		o = s.option(form.ListValue, 'operator_type', _('运营商'));
		o.value('campus', _('校园网'));
		o.value('cmcc', _('中国移动'));
		o.value('unicom', _('中国联通'));
		o.value('telecom', _('中国电信'));
		o.default = 'unicom';

		o = s.option(form.Value, 'operator_domain', _('运营商后缀'));
		o.placeholder = _('留空使用运营商；填 none 不追加后缀。');

		o = s.option(form.Value, 'account_prefix', _('账号前缀'));
		o.placeholder = ',0,';
		o.default = ',0,';

		o = s.option(form.Value, 'fixed_ip', _('固定 IP'));
		o.placeholder = _('留空发送空 IP。');

		s = m.section(form.TypedSection, '_actions', _('操作'));
		s.anonymous = true;
		s.render = function() {
			return E('div', { 'class': 'cbi-section' }, [
				E('h3', {}, _('操作')),
				E('button', {
					'class': 'btn cbi-button cbi-button-apply',
					'click': ui.createHandlerFn(this, function() {
						return fs.exec('/usr/bin/campus-auth-guardian.sh', [ 'auth' ])
							.then(function() { ui.addNotification(null, E('p', _('认证命令已执行完成。'))); })
							.catch(function(e) { ui.addNotification(null, E('p', _('认证失败：') + e.message)); });
					})
				}, _('立即认证')),
				' ',
				E('button', {
					'class': 'btn cbi-button cbi-button-action',
					'click': ui.createHandlerFn(this, function() {
						return fs.exec('/usr/bin/campus-auth-guardian.sh', [ 'check' ])
							.then(function() { ui.addNotification(null, E('p', _('网络检测结果：已在线。'))); })
							.catch(function(e) { ui.addNotification(null, E('p', _('网络检测未确认在线：') + e.message)); });
					})
				}, _('检测状态')),
				' ',
				E('button', {
					'class': 'btn cbi-button cbi-button-reload',
					'click': ui.createHandlerFn(this, function() {
						return fs.exec('/etc/init.d/campus-auth-guardian', [ 'restart' ])
							.then(function() { ui.addNotification(null, E('p', _('服务已重启。'))); })
							.catch(function(e) { ui.addNotification(null, E('p', _('重启失败：') + e.message)); });
					})
				}, _('重启服务'))
			]);
		};

		return m.render();
	}
});
