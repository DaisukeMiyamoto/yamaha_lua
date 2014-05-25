--[[
  output
    - number of used NAT port
    - number of DHCP lease
  to syslog
]]


--------------------------##  config  ##--------------------------------
-- Interval (sec)
idle_time = 600				-- ��

-- �g�p�󋵂��Ď����� IP �}�X�J���[�h�� NAT �f�B�X�N���v�^�ԍ��i1 - 2147483647�j
nat_descriptor = 200	-- ��

-- �g�p�|�[�g����臒l�i1 - NAT �����Z�b�V�������̍ő�l�j
th_port = 2000			-- ��

-- ���o������� IP �A�h���X�̌��i1, 2 ..�j
ip_num = 5	-- ��

-- ���[���̐ݒ�
mail_tbl = {					-- ��
	smtp_address = "sample.smtp.server",
	from = "rooter@brain.imi.i.u-tokyo.ac.jp",
	to = "miyamoto@brain.imi.i.u-tokyo.ac.jp"
}

-- ���[���̑��M�Ɏ��s�������ɏo�͂��� SYSLOG �̃��x���iinfo, debug, notice�j
log_level = "notice"			-- ��

----------------------##  �ݒ�l�����܂�  ##----------------------------

------------------------------------------------------------
-- IP �}�X�J���[�h�̎g�p�|�[�g����Ԃ��֐�                --
------------------------------------------------------------
function natmsq_use_status(id)
	local rtn, str, num
	local cmd = "show nat descriptor address " .. tostring(id)
	local ptn = "(%d+) used."
	
	rtn, str = rt.command(cmd)
	if (rtn) and (str) then
		num = str:match(ptn)
		if (num) then
			num = tonumber(num)
		end
	else
		str = cmd .. "�R�}���h���s���s\r\n"
	end

	return rtn, num, str
end

------------------------------------------------------------
-- get DHCP leased num                                    --
------------------------------------------------------------
function dhcp_use_status()
	local rtn, str, num
	local cmd = "show status dhcp"
	local ptn = "Leased: (%d+)"
	
	rtn, str = rt.command(cmd)
	if (rtn) and (str) then
		num = str:match(ptn)
		if (num) then
			num = tonumber(num)
		end
	else
		str = cmd .. "�R�}���h���s���s\r\n"
	end

	return rtn, num, str
end


------------------------------------------------------------
-- IP �}�X�J���[�h�̎g�p�|�[�g����                        --
-- ���� IP �A�h���X���ɋ��߂�֐�                         --
------------------------------------------------------------
function nattbl_info(str, num)
	local rt_name

	rt_name = string.match(_RT_FIRM_REVISION, "(%w+) ")
	if ((rt_name == "RTX1200") or (rt_name == "NVR500") or (rt_name == "RTX3500") or (rt_name == "RTX5000")) then
		return nattbl_info_rtx1200(str, num)
	else
		return nattbl_info_srt100(str, num)
	end
end

----------------------------------------------------------------------------
-- IP �}�X�J���[�h�̎g�p�|�[�g����                                       --
-- ���� IP �A�h���X���ɋ��߂�֐��iRTX1200�ANVR500�ARTX3500�ARTX5000 �Łj--
---------------------------------------------------------------------------
function nattbl_info_rtx1200(str, num)
	local result, n
	local ptn = "%s+%d+%s+(%d+%.%d+%.%d+%.%d+)%s+(%d+)"
	local t = {}

	n = 1
	for k, v in string.gmatch(str, ptn) do
		t[n] = {k, v}

		if (n + 1 > num) then
			break
		end
		n = n + 1
	end

	if (n < num) then
		num = n
	end

	result = string.format("�|�[�g�g�p���̑�������IP�A�h���X�i���%d�j\r\n", num)
	result = result .. string.format("No.  ����IP�A�h���X  �g�p���̃|�[�g��\r\n")
	
	for i, v in ipairs(t) do
		result = result .. string.format("%3d  %14s  %5d\r\n", i, v[1], v[2])
	end

	return result
end

------------------------------------------------------------
-- IP �}�X�J���[�h�̎g�p�|�[�g����                        --
-- ���� IP �A�h���X���ɋ��߂�֐��iSRT100 �Łj            --
------------------------------------------------------------
function nattbl_info_srt100(str, num)
	local result, n
	local ptn = "%s+%u+%s+(%d+%.%d+%.%d+%.%d+)%.%d+%s+%d+"
	local t = {}
	local a = {}

	for v in string.gmatch(str, ptn) do
		if (not t[v]) then
			t[v] = 1
		else
			t[v] = t[v] + 1
		end
	end

	n = 0
	for k, v in pairs(t) do
		a[n + 1] = {k, v}
		n = n + 1
	end

	bubble_sort(a, true)

	if (n < num) then
		num = n
	end

	result = string.format("�|�[�g�g�p���̑�������IP�A�h���X�i���%d�j\r\n", num)
	result = result .. string.format("No.  ����IP�A�h���X  �g�p���̃|�[�g��\r\n")
	
	for i, v in ipairs(a) do
		result = result .. string.format("%3d  %14s  %5d\r\n", i, v[1], v[2])
		if (i + 1 > num) then
			break
		end
	end

	return result
end

------------------------------------------------------------
-- �z��̕��ёւ����s���֐�                               --
------------------------------------------------------------
function bubble_sort(t, reverse)
	local i, j

	for i = 1, #t do
		j = #t
		while (j > i) do
			if (reverse) then
				if (t[j-1][2] < t[j][2]) then
					t[j-1], t[j] = swap(t[j-1], t[j])
				end
			else
				if (tbl[j-1][2] > tbl[j][2]) then
					t[j-1], t[j] = swap(t[j-1], t[j])
				end
			end
			j = j - 1
		end
	end
end

------------------------------------------------------------
-- 2�̒l�����ւ���֐�                                --
------------------------------------------------------------
function swap(x, y)
	local temp
	
	temp = x
	x = y
	y = temp
	return x, y
end

------------------------------------------------------------
-- ���݂̓������擾����֐�                               --
------------------------------------------------------------
function time_stamp()
	local t = {}

	t = os.date("*t")
	return string.format("%d/%02d/%02d %02d:%02d:%02d", 
		t.year, t.month, t.day, t.hour, t.min, t.sec)
end

------------------------------------------------------------
-- ���C�����[�`��                                         --
------------------------------------------------------------
local rtn, nat_use, str
local rtn_dhcp, dhcp_use, str
local title = "NAT �}�X�J���[�h�e�[�u�� �g�p�|�[�g��"
local unit = "��"

while (true) do
	mail_tbl.text = ""

	-- get NAT status
	rtn, nat_use, str = natmsq_use_status(nat_descriptor)
	if(rtn) then
		rt.syslog(log_level, string.format("[Lua/NAT] %d NAT Port Used.", nat_use))
	else
		rt.syslog(log_level, "could not get NAT used.")
	end

	-- get DHCP status
	rtn_dhcp, dhcp_use, str_dhcp = dhcp_use_status()
	if(rtn_dhcp) then
		rt.syslog(log_level, string.format("[Lua/DHCP] %d DHCP IP Used.", dhcp_use))
	else
		rt.syslog(log_level, "could not get DHCP status.")
	end



-- not send mail.
--[[
	if (rtn) then
		if (nat_use) and (str) then
			if (nat_use > th_port) then
				mail_tbl.text = mail_tbl.text .. title .. "��臒l�𒴂��Ă��܂��B\r\n"
				mail_tbl.text = mail_tbl.text .. string.format("  %s: %d%s\r\n  臒l: %d%s\r\n\r\n",
				 		title, nat_use, unit, th_port, unit) .. nattbl_info(str, ip_num)
			end
		end
	else
		mail_tbl.text = str
 	end

	if (mail_tbl.text:len() > 0) then
		mail_tbl.subject = string.format("nat masquerade table (%s)", time_stamp())
		
		rtn = rt.mail(mail_tbl)
		if (not rtn) then
			rt.syslog(log_level, "failed to send mail. (Lua �X�N���v�g�t�@�C����)")
		end
	end
]]
	rt.sleep(idle_time)
end


